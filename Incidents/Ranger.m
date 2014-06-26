////
// Ranger.m
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



@interface Ranger ()
@end



@implementation Ranger


+ (Ranger *) rangerFromJSON:(NSDictionary *)jsonRanger
                      error:(NSError **)error
{
    *error = nil;

    //
    // Utilities
    //
    
    void (^fillError)(NSString *) = ^(NSString *message) {
        *error = [[NSError alloc] initWithDomain:@"JSON"
                                            code:0
                                        userInfo:@{NSLocalizedDescriptionKey: message}];
    };
    
    NSNull *nullObject = [NSNull null];

    NSString *(^toString)(NSString *) = ^(NSString *json) {
        if (! json || json == (id)nullObject) return (NSString *)nil;
        
        if (json && [json isKindOfClass:[NSString class]]) return json;
        
        fillError(@"JSON object must be a string");
        return (NSString *)nil;
    };
    
    //
    // Parsing
    //
    
    if (! jsonRanger || ! [jsonRanger isKindOfClass:[NSDictionary class]]) {
        fillError(@"JSON object for Ranger must be a dictionary.");
        return nil;
    }

    NSString *handle = toString(jsonRanger[@"handle"]); if (*error) return nil;
    NSString *name   = toString(jsonRanger[@"name"  ]); if (*error) return nil;

    if (! handle) {
        fillError(@"Ranger handle may not be nil.");
        return nil;
    }
    
    return [[Ranger alloc] initWithHandle:handle name:name];
}


- (id) initWithHandle:(NSString *)handle
                 name:(NSString *)name
{
    if (self = [super init]) {
        self.handle = handle;
        self.name   = name;
    }
    return self;
}


- (id) copyWithZone:(NSZone *)zone
{
    Ranger *copy;
    if ((copy = [[self class] allocWithZone:zone])) {
        copy = [copy initWithHandle:self.handle name:self.name];
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
    return [self isEqualToRanger:other];
}


- (BOOL) isEqualToRanger:(Ranger *)other
{
    if (self == other) {
        return YES;
    }

    if ((self.handle != other.handle) && (! [self.handle isEqualToString: other.handle])) { return NO; }

    return YES;
}


- (NSUInteger) hash
{
    return self.handle.hash;
}


- (NSComparisonResult) compare:(Ranger *)other
{
    return [self.handle compare:other.handle];
}


- (NSString *) description
{
    return [NSString stringWithFormat:@"%@ (%@)", self.handle, self.name];
}


@end
