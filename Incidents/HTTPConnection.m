////
// HTTPConnection.m
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
#import "HTTPConnection.h"



@interface HTTPConnection () <NSConnectionDelegate>

@property (assign) BOOL active;
@property (assign) BOOL verbose;

@property (strong) NSURLRequest      *request;
@property (strong) NSHTTPURLResponse *responseInfo;
@property (strong) NSData            *responseData;

@property (strong) NSURLConnection *urlConnection;

@property (strong) HTTPResponseHandler       onSuccess;
@property (strong) HTTPAuthenticationHandler onAuthenticationChallenge;
@property (strong) HTTPErrorHandler          onError;

@end


@implementation HTTPConnection


+ (NSString *) userAgent {
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (! version) {
        version = @"UNKNOWN";
    }
    //NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    return [NSString stringWithFormat:
            @"Incidents IMS/%@",
            version
            //[processInfo operatingSystemName],
            //[processInfo operatingSystemVersionString]
            ];
}


+ (HTTPConnection *) JSONQueryConnectionWithURL:(NSURL *)url
                                responseHandler:(HTTPResponseHandler)onSuccess
                          authenticationHandler:(HTTPAuthenticationHandler)onAuthenticationChallenge
                                   errorHandler:(HTTPErrorHandler)onError
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"GET";
    request.HTTPBody = [NSData data];
    request.timeoutInterval = 2.0;
    request.HTTPShouldUsePipelining = YES;
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
    
    return [[self alloc] initWithRequest:request
                         responseHandler:onSuccess
                   authenticationHandler:onAuthenticationChallenge
                            errorHandler:onError];
}


+ (HTTPConnection *) JSONPostConnectionWithURL:(NSURL *)url
                                          body:(NSData *)body
                               responseHandler:(HTTPResponseHandler)onSuccess
                         authenticationHandler:(HTTPAuthenticationHandler)onAuthenticationChallenge
                                  errorHandler:(HTTPErrorHandler)onError
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    request.HTTPBody = body;

    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];

    return [[self alloc] initWithRequest:request
                         responseHandler:onSuccess
                   authenticationHandler:onAuthenticationChallenge
                            errorHandler:onError];
}


- (id) initWithRequest:(NSURLRequest *)request
       responseHandler:(HTTPResponseHandler)onSuccess
 authenticationHandler:(HTTPAuthenticationHandler)onAuthenticationChallenge
          errorHandler:(HTTPErrorHandler)onError
{
    if (self = [super init]) {
        self.active = YES;

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.verbose = [defaults boolForKey:@"HTTPConnectionLogging"];

        if (self.verbose) {
            NSLog(@"Sending %@ request at %@\nHeaders: %@\nBody:\n%@",
                  request.HTTPMethod, request.URL, request.allHTTPHeaderFields,
                  [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
        }

        self.request      = request;
        self.responseInfo = nil;
        self.responseData = [NSMutableData data];

        self.urlConnection = [NSURLConnection connectionWithRequest:request delegate:self];

        self.onSuccess                 = onSuccess;
        self.onAuthenticationChallenge = onAuthenticationChallenge;
        self.onError                   = onError;

        if (! self.urlConnection) {
            NSError *error = [[NSError alloc] initWithDomain:@"HTTPConnection"
                                                        code:0
                                                    userInfo:@{NSLocalizedDescriptionKey: @"Unable to initialize connection."}];
            [self reportError:error];
        }
    }
    return self;
}


- (void) reportResponse
{
    self.active = NO;
    if (self.onSuccess) {
        self.onSuccess(self);
    }
}


- (void) reportError:(NSError *)error
{
    self.active = NO;
    if (self.onError) {
        self.onError(self, error);
    }
}


- (NSAttributedString*) errorFromServer
{
    if (self.active) { return nil; }

    if (self.responseData.length == 0) { return [[NSAttributedString alloc] initWithString:@""]; }

    if ([self.responseInfo.MIMEType isEqualToString:@"text/plain"]) {
        // FIXME: We're assuming UTF-8;, could try to get the encoding from the MIME hooey or something.  Whatevs.
        NSString *message = [[NSString alloc] initWithBytes:self.responseData.bytes length:self.responseData.length encoding:NSUTF8StringEncoding];
        return [[NSAttributedString alloc] initWithString:message];
    }

    if ([self.responseInfo.MIMEType isEqualToString:@"text/html"]) {
        return [[NSAttributedString alloc] initWithHTML:self.responseData documentAttributes:NULL];
    }

    NSString *message = [NSString stringWithFormat:@"(Unable to read error content of type: %@)", self.responseInfo.MIMEType];
    return [[NSAttributedString alloc] initWithString:message];
}


@end



@implementation HTTPConnection (NSConnectionDelegate)


- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)responseInfo
{
    if (! [connection isEqual:self.urlConnection]) {
        NSLog(@"Got response from unknown connection?!?!");
        return;
    }

    if (self.verbose) {
        NSLog(@"Got %ld response with headers: %@", responseInfo.statusCode, responseInfo.allHeaderFields);
    }

    self.responseInfo = responseInfo;

    NSString *whyIDontLikeThisResponse = nil;

    if (! [responseInfo isKindOfClass:NSHTTPURLResponse.class]) {
        whyIDontLikeThisResponse = [NSString stringWithFormat:@"Unexpected (non-HTTP) response: %@", responseInfo];
    }
    else if (! [responseInfo.MIMEType isEqualToString:@"application/json"] && responseInfo.statusCode != 201) {
        whyIDontLikeThisResponse = [NSString stringWithFormat:@"Unexpected (non-JSON) MIME type: %@", responseInfo.MIMEType];
    }

    if (whyIDontLikeThisResponse) {
        NSError *error = [[NSError alloc] initWithDomain:@"HTTPConnection"
                                                    code:responseInfo.statusCode
                                                userInfo:@{NSLocalizedDescriptionKey: whyIDontLikeThisResponse}];

        [self reportError:error];
    }

    [(NSMutableData *)self.responseData setLength:0];
}


- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (! [connection isEqual:self.urlConnection]) {
        NSLog(@"Got data from unknown connection?!?!");
        return;
    }

    if (self.verbose) {
        NSLog(@"Got data:\n%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }

    [(NSMutableData *)self.responseData appendData:data];
}


- (void) connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"Authentication requested.");
    NSURLCredential *newCredential = self.onAuthenticationChallenge(self, challenge);

    [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
}


- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (! [connection isEqual:self.urlConnection]) {
        NSLog(@"Got error from unknown connection?!?!");
        return;
    }

    self.urlConnection = nil;
    self.responseData = nil;

    if (self.verbose) {
        NSLog(@"Failed with error: %@", error);
    }

    [self reportError:error];
}


- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (! [connection isEqual:self.urlConnection]) {
        NSLog(@"Got success from unknown connection?!?!");
        return;
    }

    if (self.verbose) {
        NSLog(@"Finished loading.");
    }

    [self reportResponse];
}


@end
