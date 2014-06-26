////
// HTTPConnection.h
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

#import <Foundation/Foundation.h>

@class HTTPConnection;



typedef void             (^HTTPResponseHandler)(HTTPConnection *);
typedef NSURLCredential *(^HTTPAuthenticationHandler)(HTTPConnection *, NSURLAuthenticationChallenge *);
typedef void             (^HTTPErrorHandler)(HTTPConnection *, NSError *);



@interface HTTPConnection : NSObject

@property (assign,readonly) BOOL active;

@property (strong,readonly) NSURLRequest      *request;
@property (strong,readonly) NSHTTPURLResponse *responseInfo;
@property (strong,readonly) NSData            *responseData;


+ (HTTPConnection *) JSONQueryConnectionWithURL:(NSURL *)url
                                responseHandler:(HTTPResponseHandler)onSuccess
                          authenticationHandler:(HTTPAuthenticationHandler)onAuthenticationChallenge
                                   errorHandler:(HTTPErrorHandler)onError;

+ (HTTPConnection *) JSONPostConnectionWithURL:(NSURL *)url
                                          body:(NSData *)body
                               responseHandler:(HTTPResponseHandler)onSuccess
                         authenticationHandler:(HTTPAuthenticationHandler)onAuthenticationChallenge
                                  errorHandler:(HTTPErrorHandler)onError;

- (id) initWithRequest:(NSURLRequest *)request
       responseHandler:(HTTPResponseHandler)onSuccess
 authenticationHandler:(HTTPAuthenticationHandler)onAuthenticationChallenge
          errorHandler:(HTTPErrorHandler)onError;

- (NSAttributedString*) errorFromServer;


@end
