////
// Incident.m
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

#import "Ranger.h"
#import "Location.h"
#import "ReportEntry.h"
#import "Incident.h"



NSString *rfc3339StringFromDate(NSDate *date);
NSDate *dateFromRFC3339String(NSString *rfc3339String);



@interface Incident ()

@property (strong,readonly) NSArray *rangers;

@end



@implementation Incident


+ (Incident *) incidentInDataStore:(id <DataStoreProtocol>)dataStore
                          fromJSON:(NSDictionary *)jsonIncident
                             error:(NSError **)error
{
    NSNull *nullObject = [NSNull null];

    *error = nil;

    //
    // Utilities
    //

    void (^fillError)(NSString *) = ^(NSString *message) {
        *error = [[NSError alloc] initWithDomain:@"JSON"
                                            code:0
                                        userInfo:@{NSLocalizedDescriptionKey: message}];
    };

    NSString *(^toString)(NSString *) = ^(NSString *json) {
        if (! json || json == (id)nullObject) return (NSString *)nil;

        if (json && [json isKindOfClass:[NSString class]]) return json;

        fillError(@"JSON object must be a string");
        return (NSString *)nil;
    };
    
    NSNumber *(^toNumber)(NSNumber *) = ^(NSNumber *json) {
        if (! json || json == (id)nullObject) return (NSNumber *)nil;

        if (json && [json isKindOfClass:[NSNumber class]]) return json;

        fillError(@"JSON object must be a number.");
        return (NSNumber *)nil;
    };

    BOOL (^toBOOL)(NSNumber *) = ^(NSNumber *json) {
        if (json == (NSNumber *)kCFBooleanFalse) return NO;
        if (json == (NSNumber *)kCFBooleanTrue ) return YES;

        fillError(@"JSON object must be a boolean.");
        return (BOOL)jsonIncident;
    };

    NSArray *(^toArray)(NSArray *) = ^(NSArray *json) {
        if (! json || json == (id)nullObject) return (NSArray *)nil;

        if (json && [json isKindOfClass:[NSArray class]]) return json;

        fillError(@"JSON object must be an array.");
        return (NSArray *)nil;
    };

    NSDate *(^toDate)(NSString *) = ^(NSString *json) {
        if (! json || json == (id)nullObject) return (NSDate *)nil;

        if (json && [json isKindOfClass:[NSString class]]) return dateFromRFC3339String(json);

        fillError(@"JSON date object must be a string.");
        return (NSDate *)nil;
    };

    if (! jsonIncident || ! [jsonIncident isKindOfClass:[NSDictionary class]]) {
        fillError(@"JSON object for Incident must be a dictionary.");
        return nil;
    }

    NSArray *rangerHandlesJSON = jsonIncident[@"ranger_handles"];
    if (! [rangerHandlesJSON isKindOfClass:[NSArray class]]) {
        fillError(@"JSON for ranger handles must be an array.");
        return nil;
    }
    NSMutableArray *rangers = [NSMutableArray arrayWithCapacity:rangerHandlesJSON.count];
    NSDictionary *allRangersByHandle = dataStore.allRangersByHandle;
    for (NSString *rangerHandle in rangerHandlesJSON) {
        Ranger *ranger = allRangersByHandle[rangerHandle];
        if (! ranger) {
            ranger = [[Ranger alloc] initWithHandle:rangerHandle name:nil];
        }
        [rangers addObject:ranger];
    }

    NSArray *reportEntriesJSON = jsonIncident[@"report_entries"];
    if (! [reportEntriesJSON isKindOfClass:[NSArray class]]) {
        fillError(@"JSON for report entries must be an array.");
        return nil;
    }
    NSMutableArray *reportEntries = [NSMutableArray arrayWithCapacity:reportEntriesJSON.count];
    for (NSDictionary *reportEntryJSON in reportEntriesJSON) {
        ReportEntry *reportEntry = [[ReportEntry alloc] initWithAuthor:toString(reportEntryJSON[@"author"])
                                                                  text:toString(reportEntryJSON[@"text"])
                                                           createdDate:toDate(reportEntryJSON[@"created"])
                                                           systemEntry:toBOOL(reportEntryJSON[@"system_entry"])];
        [reportEntries addObject:reportEntry];
    }

    Location *location = [[Location alloc] initWithName:jsonIncident[@"location_name" ]
                                                address:jsonIncident[@"location_address"]];

    NSNumber *number     = toNumber(jsonIncident[@"number"        ]); if (*error) return nil;
    NSArray  *types      = toArray (jsonIncident[@"incident_types"]); if (*error) return nil;
    NSString *summary    = toString(jsonIncident[@"summary"       ]); if (*error) return nil;
    NSDate   *created    = toDate  (jsonIncident[@"created"       ]); if (*error) return nil;
    NSDate   *dispatched = toDate  (jsonIncident[@"dispatched"    ]); if (*error) return nil;
    NSDate   *onScene    = toDate  (jsonIncident[@"on_scene"      ]); if (*error) return nil;
    NSDate   *closed     = toDate  (jsonIncident[@"closed"        ]); if (*error) return nil;
    NSNumber *priority   = toNumber(jsonIncident[@"priority"      ]); if (*error) return nil;

    return [[Incident alloc] initInDataStore:dataStore
                                  withNumber:number
                                     rangers:rangers
                                    location:location
                                       types:types
                                     summary:summary
                               reportEntries:reportEntries
                                     created:created
                                  dispatched:dispatched
                                     onScene:onScene
                                      closed:closed
                                    priority:priority];
}


- (id) initInDataStore:(id <DataStoreProtocol>)dataStore
            withNumber:(NSNumber *)number
{
    return [self initInDataStore:dataStore
                      withNumber:number
                         rangers:@[]
                        location:nil
                           types:@[]
                         summary:nil
                   reportEntries:@[]
                         created:[NSDate date]
                      dispatched:nil
                         onScene:nil
                          closed:nil
                        priority:@3];
}


- (id) initInDataStore:(id <DataStoreProtocol>)dataStore
            withNumber:(NSNumber *)number
               rangers:(NSArray *)rangers
              location:(Location *)location
                 types:(NSArray *)types
               summary:(NSString *)summary
         reportEntries:(NSArray *)reportEntries
               created:(NSDate *)created
            dispatched:(NSDate *)dispatched
               onScene:(NSDate *)onScene
                closed:(NSDate *)closed
              priority:(NSNumber *)priority
{
    if (self = [super init]) {
//        if (! location) {
//            location = [[Location alloc] initWithName:nil address:nil];
//        }

        self.dataStore       = dataStore;
        self.number          = number;
        self.rangers         = rangers;
        self.location        = [location copy];
        self.types           = [types mutableCopy];
        self.summary         = summary;
        self.reportEntries   = [reportEntries mutableCopy];
        self.created         = created;
        self.dispatched      = dispatched;
        self.onScene         = onScene;
        self.closed          = closed;
        self.priority        = priority;
    }
    return self;
}


- (id) copyWithZone:(NSZone *)zone
{
    Incident *copy;
    if ((copy = [[self class] allocWithZone:zone])) {
        copy = [copy initInDataStore:self.dataStore
                          withNumber:self.number
                             rangers:self.rangers
                            location:self.location
                               types:self.types
                             summary:self.summary
                       reportEntries:self.reportEntries
                             created:self.created
                          dispatched:self.dispatched
                             onScene:self.onScene
                              closed:self.closed
                            priority:self.priority];
    }
    return copy;
}


- (BOOL) isEqual:(id)other
{
    if (other == self) {
        return YES;
    }
    if (! other || ! [other isKindOfClass:self.class]) {
        return NO;
    }
    return [self isEqualToIncident:other];
}


- (BOOL) isEqualToIncident:(Incident *)other
{
    if (self == other) {
        return YES;
    }

    id <DataStoreProtocol> dataStore = self.dataStore;

    if ((     dataStore     != other.dataStore    ) && (! [     dataStore     isEqual:           other.dataStore    ])) { return NO; }
    if ((self.number        != other.number       ) && (! [self.number        isEqualToNumber:   other.number       ])) { return NO; }
    if ((self.rangers       != other.rangers      ) && (! [self.rangers       isEqualToArray:    other.rangers      ])) { return NO; }
    if ((self.location      != other.location     ) && (! [self.location      isEqualToLocation: other.location     ])) { return NO; }
    if ((self.types         != other.types        ) && (! [self.types         isEqualToArray:    other.types        ])) { return NO; }
    if ((self.summary       != other.summary      ) && (! [self.summary       isEqualToString:   other.summary      ])) { return NO; }
    if ((self.reportEntries != other.reportEntries) && (! [self.reportEntries isEqualToArray:    other.reportEntries])) { return NO; }
    if ((self.created       != other.created      ) && (! [self.created       isEqualToDate:     other.created      ])) { return NO; }
    if ((self.dispatched    != other.dispatched   ) && (! [self.dispatched    isEqualToDate:     other.dispatched   ])) { return NO; }
    if ((self.onScene       != other.onScene      ) && (! [self.onScene       isEqualToDate:     other.onScene      ])) { return NO; }
    if ((self.closed        != other.closed       ) && (! [self.closed        isEqualToDate:     other.closed       ])) { return NO; }
    if ((self.priority      != other.priority     ) && (! [self.priority      isEqualToNumber:   other.priority     ])) { return NO; }

    return YES;
}


- (NSString *) description
{
    NSString *state;
    if      (self.closed    ) { state = @"closed"    ; }
    else if (self.onScene   ) { state = @"on scene"  ; }
    else if (self.dispatched) { state = @"dispatched"; }
    else if (self.created   ) { state = @"new"       ; }
    else                      { state = @"NONE"      ; }


    NSString *description = nil;
    for (Ranger* ranger in self.rangers) {
        if (description) {
            description = [description stringByAppendingFormat:@", %@", ranger.handle];
        }
        else {
            description = [@"(" stringByAppendingString:ranger.handle];
        }
    }
    if (description) {
        description = [description stringByAppendingFormat:@" @ %@)", self.location.name];
    }
    else {
        description = [NSString stringWithFormat:@"@ %@", self.location.name];
    }
    
    return [NSString stringWithFormat:
               @"Incident #%@ (%@) %@: %@",
               self.number, state, description, self.summaryFromReport];
}


- (BOOL) isNew
{
    return (self.number.integerValue < 0);
}


- (NSDictionary *) asJSON{
    NSNull *nullObject = [NSNull null];

    id (^nilNULL)(id) = ^(id object) {
        if (! object) {
            return (id)nullObject;
        }
        else {
            return object;
        }
    };

    id (^jsonDate)(NSDate *) = ^(NSDate *date) {
        if (! date) {
            return (id)[NSNull null];
        }
        else {
            return (id)rfc3339StringFromDate(date);
        }
    };

    NSMutableArray *reportEntriesAsJSON = [NSMutableArray arrayWithCapacity:self.reportEntries.count];
    for (ReportEntry *entry in self.reportEntries) {
        [reportEntriesAsJSON addObject:@{
            @"author" : nilNULL(entry.author),
            @"text"   : nilNULL(entry.text),
            @"created": jsonDate(entry.createdDate),
        }];
    }

    return @{
        @"number"          : nilNULL(self.number),
        @"ranger_handles"  : nilNULL(self.rangersByHandle.allKeys),
        @"location_name"   : nilNULL(self.location.name),
        @"location_address": nilNULL(self.location.address),
        @"incident_types"  : nilNULL(self.types),
        @"summary"         : nilNULL(self.summary),
        @"report_entries"  : nilNULL(reportEntriesAsJSON),
        @"created"         : jsonDate(self.created),
        @"dispatched"      : jsonDate(self.dispatched),
        @"on_scene"        : jsonDate(self.onScene),
        @"closed"          : jsonDate(self.closed),
        @"priority"        : nilNULL(self.priority),
    };
}


- (NSArray *) rangers
{
    if (! self.rangersByHandle) { return nil; }

    return self.rangersByHandle.allValues;
}


- (void) setRangers:(NSArray *)rangers
{
    if (rangers) {
        NSMutableDictionary *rangersByHandle = [NSMutableDictionary dictionaryWithCapacity:rangers.count];

        for (Ranger *ranger in rangers) {
            rangersByHandle[ranger.handle] = ranger;
        }

        self.rangersByHandle = rangersByHandle;
    }
    else {
        self.rangersByHandle = nil;
    }
}


- (void) addRanger:(Ranger *)ranger
{
    if (! self.rangersByHandle) { self.rangers = @[]; }

    ((NSMutableDictionary*)self.rangersByHandle)[ranger.handle] = ranger;
}


- (void) removeRanger:(Ranger *)ranger
{
    if (! self.rangersByHandle) { return; }

    [(NSMutableDictionary *)self.rangersByHandle removeObjectForKey:ranger.handle];
}


- (NSUInteger) addEntryToReport:(ReportEntry *)entry
{
    NSUInteger count = self.reportEntries.count;
    [(NSMutableArray *)self.reportEntries insertObject:entry atIndex:count];
    return count;
}


- (NSString *) summaryFromReport {
    if (self.summary && self.summary.length) {
        return self.summary;
    }

    for (ReportEntry *entry in self.reportEntries) {
        if (entry.systemEntry) {
            continue;
        }

        __block NSString *firstLine = nil;
        [entry.text enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            firstLine = line;
            *stop = YES;
        }];

        return firstLine;
    }
    return @"";
}


- (NSString *) summaryOfRangers
{
    return [self.rangersByHandle.allKeys componentsJoinedByString:@", "];
}


- (NSString *) summaryOfTypes
{
    return [self.types componentsJoinedByString:@", "];
}


@end



static NSDateFormatter *rfc3339DayTimeFormatter = nil;

NSDateFormatter *_rfc3339DateFormatter(void);
NSDateFormatter *_rfc3339DateFormatter(void) {
    if (! rfc3339DayTimeFormatter) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

        [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];

        rfc3339DayTimeFormatter = formatter;
    }
    return rfc3339DayTimeFormatter;
}

NSString *rfc3339StringFromDate(NSDate *date)
{
    return [_rfc3339DateFormatter() stringFromDate:date];
}

NSDate *dateFromRFC3339String(NSString *rfc3339String)
{
    return [_rfc3339DateFormatter() dateFromString:rfc3339String];
}
