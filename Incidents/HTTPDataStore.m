////
// HTTPDataStore.m
// Incidents
////
// See the file COPYRIGHT for copyright information.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
////

#import "utilities.h"
#import "Ranger.h"
#import "Incident.h"
#import "Location.h"
#import "HTTPConnection.h"
#import "HTTPDataStore.h"



@interface HTTPDataStore ()


@property (strong) NSURL *url;

@property (assign) BOOL serverAvailable;

@property (strong) HTTPConnection *pingConnection;
@property (strong) HTTPConnection *loadLinksConnection;
@property (strong) HTTPConnection *loadIncidentNumbersConnection;
@property (strong) HTTPConnection *loadIncidentConnection;
@property (strong) HTTPConnection *loadRangersConnection;
@property (strong) HTTPConnection *loadIncidentTypesConnection;

@property (strong) NSMutableDictionary *allIncidentsByNumber;

@property (strong) NSMutableDictionary *incidentETagsByNumber;
@property (strong) NSMutableSet        *incidentsNumbersToLoad;


@end



@implementation HTTPDataStore


- (id) initWithURL:(NSURL *)url
{
    if (self = [super init]) {
        self.url = url;

        self.allIncidentsByNumber   = [NSMutableDictionary dictionary];
        self.incidentETagsByNumber  = [NSMutableDictionary dictionary];
        self.incidentsNumbersToLoad = [NSMutableSet set];

        self.serverAvailable = NO;
    }
    return self;
}


@synthesize delegate=_delegate;


- (NSArray *) incidents
{
    if (! self.allIncidentsByNumber) {
        return @[];
    }
    else {
        return self.allIncidentsByNumber.allValues;
    }
}


- (Incident *) incidentWithNumber:(NSNumber *)number
{
    if (! self.allIncidentsByNumber) {
        return nil;
    }
    else {
        return self.allIncidentsByNumber[number];
    }
}


- (HTTPAuthenticationHandler) authenticationHandler {
    id <DataStoreDelegate> delegate = self.delegate;

    if (delegate) {
        return ^(HTTPConnection *connection, NSURLAuthenticationChallenge *challenge) {
            return [delegate credentialForChallenge:challenge];
        };
    }
    else {
        return nil;
    }
}


static int nextTemporaryNumber = -1;

- (Incident *) createNewIncident
{
    if (! self.allIncidentsByNumber) {
        return nil;
    }

    NSNumber *temporaryNumber = [NSNumber numberWithInt:nextTemporaryNumber--];
    
    while (self.allIncidentsByNumber[temporaryNumber]) {
        temporaryNumber = [NSNumber numberWithInteger:temporaryNumber.integerValue-1];
    }
    
    return [[Incident alloc] initInDataStore:self withNumber:temporaryNumber];
}


- (void) updateIncident:(Incident *)incident
{
    if (! incident || ! incident.number) {
        performAlert(@"Cannot commit invalid incident: %@", incident);
        return;
    }

    NSURL *url = [self.url URLByAppendingPathComponent:@"incidents/"];
    NSInteger expectedStatusCode;
    NSNumber *incidentNumberToReplace = nil;

    if (incident.isNew) {
        // This is a new incident, upload without an assigned number.
        incident = [incident copy];
        incidentNumberToReplace = incident.number;
        incident.number = nil;

        expectedStatusCode = 201;
    }
    else {
        // We're updating an existing incident; POST to it directly.
        url = [url URLByAppendingPathComponent:incident.number.stringValue];

        expectedStatusCode = 200;
    }

    NSData *body;
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL verbose = [defaults boolForKey:@"HTTPConnectionLogging"];

        NSUInteger options = 0;
        if (verbose) { options = NSJSONWritingPrettyPrinted; } // If we're logging traffic, make it more readable.

        NSError *error;
        body = [NSJSONSerialization dataWithJSONObject:[incident asJSON] options:options error:&error];
        if (! body) {
            performAlert(@"Unable to serialize incident %@ to JSON: %@", incident, error);
            return;
        }
    }

    __block NSError *connectionError = nil;

    HTTPResponseHandler onResponse = ^(HTTPConnection *connection) {
        if (! incident.number) {
            // This was a new incident. Find the number assigned to it in the reponse headers.
            NSString *numberHeader = connection.responseInfo.allHeaderFields[@"Incident-Number"];
            if (! numberHeader) {
                performAlert(@"No number provided for new incident.");
                return;
            }
            incident.number = [NSNumber numberWithInteger:numberHeader.integerValue];
        }

        NSLog(@"Incident #%@ update request completed.", incident.number);

        if (connection.responseData.length != 0) {
            NSLog(@"Incident #%@ update request got response data (not expected): %@", incident.number, self.pingConnection.responseData);
        }

        if (connection.responseInfo.statusCode != expectedStatusCode) {
            performAlert(@"Incident #%@ update request got status %ld, expected %ld.\n%@",
                         incident.number, connection.responseInfo.statusCode, expectedStatusCode, connection.errorFromServer);
            return;
        }

        if (connectionError) {
            performAlert(@"Incident #%@ update request failed: %@\n----\n%@",
                         incident.number, connectionError.localizedDescription, connection.errorFromServer);
            NSLog(@"Unable to connect to server to update incident #%@: %@", incident.number, connectionError);
            return;
        }

        NSLog(@"Updated: %@", incident);

        [self loadIncidentNumber:incident.number];

        if (incidentNumberToReplace) {
            id <DataStoreDelegate> delegate = self.delegate;
            [delegate dataStore:self didReplaceIncidentNumbered:incidentNumberToReplace withIncidentNumbered:incident.number];
        }
    };

    HTTPErrorHandler onError = ^(HTTPConnection *connection, NSError *error) {
        connectionError = error;
    };

    [HTTPConnection JSONPostConnectionWithURL:url
                                         body:body
                              responseHandler:onResponse
                        authenticationHandler:self.authenticationHandler
                                 errorHandler:onError];
}


- (BOOL) serverAvailable {
    return _serverAvailable;
}
@synthesize serverAvailable=_serverAvailable;


- (void) setServerAvailable:(BOOL)available
{
    if (available != _serverAvailable) {
        _serverAvailable = available;

        if (available) {
            NSLog(@"Server connection is available.");
        }
        else {
            NSLog(@"Server connection is no longer available.");
        }
    }
}


- (void) pingServer
{
    @synchronized(self) {
        if (! self.pingConnection.active) {
            NSURL *url = [self.url URLByAppendingPathComponent:@"ping/"];

            HTTPResponseHandler onResponse = ^(HTTPConnection *connection) {
                if (connection != self.pingConnection) {
                    performAlert(@"Ping response from unknown connection!?");
                    return;
                }

                NSError *error = nil;
                NSString *jsonACK = [NSJSONSerialization JSONObjectWithData:connection.responseData
                                                                    options:NSJSONReadingAllowFragments
                                                                      error:&error];

                if (jsonACK) {
                    if ([jsonACK isEqualToString:@"ack"]) {
                        self.serverAvailable = YES;
                        //NSLog(@"Ping request succeeded.");
                        [self loadLinks];
                        [self loadIncidentTypes];
                        [self loadRangers];
                        [self loadIncidents];
                    }
                    else {
                        performAlert(@"Unexpected response to ping: %@", jsonACK);
                        self.serverAvailable = NO;
                    }
                }
                else {
                    performAlert(@"Unable to deserialize ping response: %@", error);
                }
            };

            HTTPErrorHandler onError = ^(HTTPConnection *connection, NSError *error) {
                if (connection != self.pingConnection) {
                    performAlert(@"Ping error from unknown connection!?");
                    return;
                }

                self.serverAvailable = NO;

                performAlert(@"Unable to connect to server to ping: %@", error.localizedDescription);
                NSLog(@"Unable to connect to server to ping: %@", error);
            };

            self.pingConnection = [HTTPConnection JSONQueryConnectionWithURL:url
                                                             responseHandler:onResponse
                                                       authenticationHandler:self.authenticationHandler
                                                                errorHandler:onError];
        }
    }
}


- (void) load
{
    [self pingServer];
}


- (NSURLConnection *) getJSONConnectionForPath:(NSString *)path
{
    NSURL *url = [self.url URLByAppendingPathComponent:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:[NSData data]];

    return [NSURLConnection connectionWithRequest:request delegate:self];
}


- (void) loadLinks {
    @synchronized(self) {
        if (self.serverAvailable) {
            if (! self.loadLinksConnection.active) {
                NSURL *url = [self.url URLByAppendingPathComponent:@"links/"];

                HTTPResponseHandler onResponse = ^(HTTPConnection *connection) {
                    if (connection != self.loadLinksConnection) {
                        performAlert(@"Load links response from unknown connection!?");
                        return;
                    }

                    //NSLog(@"Load links request completed.");

                    NSError *error = nil;
                    NSArray *jsonLinks = [NSJSONSerialization JSONObjectWithData:connection.responseData
                                                                         options:0
                                                                           error:&error];

                    if (! jsonLinks || ! [jsonLinks isKindOfClass:[NSArray class]]) {
                        NSLog(@"JSON object for links must be an array: %@", jsonLinks);
                        return;
                    }

                    id <DataStoreDelegate> delegate = self.delegate;
                    [delegate dataStore:self didUpdateLinks:jsonLinks];
                };

                HTTPErrorHandler onError = ^(HTTPConnection *connection, NSError *error) {
                    if (connection != self.loadLinksConnection) {
                        performAlert(@"Load links error from unknown connection!?");
                        return;
                    }

                    performAlert(@"Load links request at %@ failed: %@", url, error);
                };

                self.loadLinksConnection = [HTTPConnection JSONQueryConnectionWithURL:url
                                                                      responseHandler:onResponse
                                                                authenticationHandler:self.authenticationHandler
                                                                         errorHandler:onError];
            }
        }
    }
}


- (void) loadIncidents
{
    @synchronized(self) {
        if (! self.loadIncidentNumbersConnection.active) {
            NSURL *url = [self.url URLByAppendingPathComponent:@"incidents/"];

            HTTPResponseHandler onResponse = ^(HTTPConnection *connection) {
                if (connection != self.loadIncidentNumbersConnection) {
                    performAlert(@"Load incident numbers response from unknown connection!?");
                    return;
                }

                //NSLog(@"Load incident numbers request completed.");

                NSError *error = nil;
                NSArray *jsonNumbers = [NSJSONSerialization JSONObjectWithData:connection.responseData
                                                                       options:0
                                                                         error:&error];

                if (! jsonNumbers || ! [jsonNumbers isKindOfClass:[NSArray class]]) {
                    NSLog(@"JSON object for incident numbers must be an array: %@", jsonNumbers);
                    performAlert(@"Unable to read incident numbers from server.");
                    return;
                }

                for (NSArray *jsonNumber in jsonNumbers) {
                    if (! jsonNumber || ! [jsonNumber isKindOfClass:[NSArray class]] || [jsonNumber count] < 2) {
                        NSLog(@"JSON object for incident number must be an array of two items: %@", jsonNumber);
                        performAlert(@"Unable to read incident number from server.");
                        return;
                    }

                    // jsonNumber is (number, etag)
                    NSNumber *number = jsonNumber[0];
                    NSString *etag   = jsonNumber[1];

                    NSString *lastETag = self.incidentETagsByNumber[jsonNumber[0]];

                    if (lastETag && etag && [lastETag isEqualToString:etag]) {
                        //NSLog(@"Not loading incident #%@; already have it, etag = %@", number, etag);
                        continue;
                    }

                    if (! etag) {
                        NSLog(@"Load incident numbers reponse did not include an etag for incident #%@.", number);
                    }

                    [self.incidentsNumbersToLoad addObject:number];
                }

                // FIXME: Run through self.allIncidentsByNumber and verify that all are in self.incidentsNumbersToLoad.
                //    …if not, that's an error of some sort, since we don't remove incidents.
                    
                [self loadQueuedIncidents];
            };

            HTTPErrorHandler onError = ^(HTTPConnection *connection, NSError *error) {
                if (connection != self.loadIncidentNumbersConnection) {
                    performAlert(@"Load incident numbers error from unknown connection!?");
                    return;
                }

                performAlert(@"Load incident numbers request failed: %@", error);
            };

            self.loadIncidentNumbersConnection = [HTTPConnection JSONQueryConnectionWithURL:url
                                                                            responseHandler:onResponse
                                                                      authenticationHandler:self.authenticationHandler
                                                                               errorHandler:onError];
        }
    }
}


- (void) loadIncidentNumber:(NSNumber *)number {
    @synchronized(self) {
        [self.incidentsNumbersToLoad addObject:number];
        [self loadQueuedIncidents];
    }
}


- (void) loadQueuedIncidents {
    @synchronized(self) {
        if (self.serverAvailable) {
            if (self.loadIncidentConnection.active) {
                //
                // This shouldn't happen given how this code is wired up.
                // Logging here in case that cases accidentally, in case it's a performance oopsie.
                //
                NSLog(@"Already loading incidents... we shouldn't be here.");
            }
            else {
                id <DataStoreDelegate> delegate = self.delegate;
                NSString *path = nil;
                // FIXME: Reverse sort incidentsNumbersToLoad
                for (NSNumber *number in self.incidentsNumbersToLoad) {
                    //NSLog(@"Loading queued incident: %@", number);

                    path = [NSString stringWithFormat:@"incidents/%@", number];
                    NSURL *url = [self.url URLByAppendingPathComponent:path];

                    HTTPResponseHandler onResponse = ^(HTTPConnection *connection) {
                        if (connection != self.loadIncidentConnection) {
                            performAlert(@"Load incident #%@ request from unknown connection!?", number);
                            return;
                        }

                        //NSLog(@"Load incident request completed.");

                        NSError *error = nil;
                        NSDictionary *jsonIncident = [NSJSONSerialization JSONObjectWithData:connection.responseData
                                                                                     options:0
                                                                                       error:&error];
                        Incident *incident = [Incident incidentInDataStore:self fromJSON:jsonIncident error:&error];

                        if (incident) {
                            if ([incident.number isEqualToNumber:number]) {
                                NSString *etag = connection.responseInfo.allHeaderFields[@"ETag"];
                                if (etag) {
                                    self.incidentETagsByNumber[number] = etag;
                                }
                                else {
                                    NSLog(@"Load incident #%@ response did not include an etag.", number);
                                    [self.incidentETagsByNumber removeObjectForKey:number];
                                }
                                self.allIncidentsByNumber[number] = incident;

                                //NSLog(@"Loaded: %@", incident);
                                [delegate dataStore:self didUpdateIncident:incident];
                            }
                            else {
                                performAlert(@"Got incident #%@ when I asked for incident #%@.  I'm confused.",
                                             incident.number, number);
                            }
                        }
                        else {
                            performAlert(@"Unable to deserialize incident #%@: %@", number, error);
                        }

                        // De-queue the incident
                        [self.incidentsNumbersToLoad removeObject:number];

                        [self loadQueuedIncidents];
                    };

                    HTTPErrorHandler onError = ^(HTTPConnection *connection, NSError *error) {
                        if (connection != self.loadIncidentConnection) {
                            performAlert(@"Load incident #%@ error from unknown connection!?", number);
                            return;
                        }

                        performAlert(@"Load incident #%@ request failed: %@", number, error);
                    };

                    self.loadIncidentConnection = [HTTPConnection JSONQueryConnectionWithURL:url
                                                                             responseHandler:onResponse
                                                                       authenticationHandler:self.authenticationHandler
                                                                                errorHandler:onError];

                    [delegate dataStore:self willUpdateIncidentNumbered:number];

                    break;
                }
                if (! path) {
                    NSLog(@"Done loading queued incidents.");
                    [delegate dataStoreDidUpdateIncidents:self];
                }
            }
        }
    }
}


- (void) loadRangers {
    @synchronized(self) {
        if (self.serverAvailable) {
            if (! self.loadRangersConnection.active) {
                NSURL *url = [self.url URLByAppendingPathComponent:@"rangers/"];

                HTTPResponseHandler onResponse = ^(HTTPConnection *connection) {
                    if (connection != self.loadRangersConnection) {
                        performAlert(@"Load Rangers response from unknown connection!?");
                        return;
                    }

                    //NSLog(@"Load Rangers request completed.");

                    NSError *error = nil;
                    NSArray *jsonRangers = [NSJSONSerialization JSONObjectWithData:connection.responseData
                                                                           options:0
                                                                             error:&error];

                    if (! jsonRangers || ! [jsonRangers isKindOfClass:[NSArray class]]) {
                        NSLog(@"JSON object for Rangers must be an array: %@", jsonRangers);
                        return;
                    }

                    NSMutableDictionary *rangers = [[NSMutableDictionary alloc] initWithCapacity:jsonRangers.count];
                    for (NSDictionary *jsonRanger in jsonRangers) {
                        Ranger *ranger = [Ranger rangerFromJSON:jsonRanger error:&error];
                        if (ranger) {
                            rangers[ranger.handle] = ranger;
                        }
                        else {
                            NSLog(@"Invalid JSON: %@", jsonRanger);
                            performAlert(@"Unable to read Rangers from server: %@", error);
                        }
                    }
                    _allRangersByHandle = rangers;
                };

                HTTPErrorHandler onError = ^(HTTPConnection *connection, NSError *error) {
                    if (connection != self.loadRangersConnection) {
                        performAlert(@"Load Rangers error from unknown connection!?");
                        return;
                    }

                    performAlert(@"Load Rangers request failed: %@", error);
                };

                self.loadRangersConnection = [HTTPConnection JSONQueryConnectionWithURL:url
                                                                        responseHandler:onResponse
                                                                  authenticationHandler:self.authenticationHandler
                                                                           errorHandler:onError];
            }
        }
    }
}


- (NSDictionary *) allRangersByHandle
{
    if (! _allRangersByHandle) {
        [self loadRangers];
    }
    return _allRangersByHandle;
}
@synthesize allRangersByHandle=_allRangersByHandle;


- (void) loadIncidentTypes
{
    @synchronized(self) {
        if (self.serverAvailable) {
            if (! self.loadIncidentTypesConnection.active) {
                NSURL *url = [self.url URLByAppendingPathComponent:@"incident_types/"];

                HTTPResponseHandler onResponse = ^(HTTPConnection *connection) {
                    if (connection != self.loadIncidentTypesConnection) {
                        performAlert(@"Load Rangers response from unknown connection!?");
                        return;
                    }

                    //NSLog(@"Load incident types request completed.");

                    NSError *error = nil;
                    NSArray *jsonIncidentTypes = [NSJSONSerialization JSONObjectWithData:connection.responseData
                                                                                 options:0
                                                                                   error:&error];

                    if (! jsonIncidentTypes || ! [jsonIncidentTypes isKindOfClass:[NSArray class]]) {
                        NSLog(@"JSON object for incident types must be an array: %@", jsonIncidentTypes);
                        performAlert(@"Unable to read incident types from server.");
                        return;
                    }

                    NSMutableArray *incidentTypes = [[NSMutableArray alloc] initWithCapacity:jsonIncidentTypes.count];
                    for (NSString *incidentType in jsonIncidentTypes) {
                        if (incidentType && [incidentType isKindOfClass:[NSString class]]) {
                            [incidentTypes addObject:incidentType];
                        }
                        else {
                            NSLog(@"Invalid JSON: %@", incidentType);
                            performAlert(@"Unable to read incident types from server: %@", error);
                        }
                    }
                    _allIncidentTypes = incidentTypes;
                };

                HTTPErrorHandler onError = ^(HTTPConnection *connection, NSError *error) {
                    if (connection != self.loadIncidentTypesConnection) {
                        performAlert(@"Load Rangers error from unknown connection!?");
                        return;
                    }

                    performAlert(@"Load incident types request failed: %@", error);
                };

                self.loadIncidentTypesConnection = [HTTPConnection JSONQueryConnectionWithURL:url
                                                                              responseHandler:onResponse
                                                                        authenticationHandler:self.authenticationHandler
                                                                                 errorHandler:onError];
            }
        }
    }
}


- (NSArray *) allIncidentTypes
{
    if (! _allIncidentTypes) {
        [self loadIncidentTypes];
    }
    return _allIncidentTypes;
}
@synthesize allIncidentTypes=_allIncidentTypes;


- (NSArray *) allLocationNames
{
    NSArray *incidents = self.incidents;
    NSMutableSet *locationNames = [NSMutableSet setWithCapacity:incidents.count];

    for (Incident *incident in incidents) {
        NSString *locationName = incident.location.name;
        if (locationName && locationName.length > 0) {
            [locationNames addObject:locationName];
        }
    }

    return locationNames.allObjects;
}


- (NSArray *) addressesForLocationName:(NSString *)locationName {
    NSArray *incidents = self.incidents;
    NSMutableSet *addresses = [NSMutableSet set];

    for (Incident *incident in incidents) {
        if ([locationName isEqualToString:incident.location.name]) {
            NSString *address = incident.location.address;
            if (address && address.length > 0) {
                [addresses addObject:address];
            }
        }
    }

    return addresses.allObjects;
}


@end
