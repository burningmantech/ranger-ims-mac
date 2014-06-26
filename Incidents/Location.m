////
// Location.m
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

#import "Location.h"



@interface Location ()
@end



@implementation Location


- (id) initWithName:(NSString *)name
            address:(NSString *)address
{
    if (self = [super init]) {
        id nsnull = [NSNull null];

        if (! name    || name    == nsnull) { name    = @""; }
        if (! address || address == nsnull) { address = @""; }

        self.name    = name;
        self.address = address;
    }
    return self;
}


- (id) copyWithZone:(NSZone *)zone
{
    Location *copy;
    if ((copy = [[self class] allocWithZone:zone])) {
        copy = [copy initWithName:self.name
                          address:self.address];
    }
    return copy;
}


- (NSString *)description {
    if (self.name.length > 0) {
        if (self.address.length > 0) {
            return [NSString stringWithFormat:@"%@ (%@)", self.name, self.address];
        } else {
            return self.name;
        }
    } else {
        if (self.address.length > 0) {
            return [NSString stringWithFormat:@"(%@)", self.address];
        } else {
            return @"";
        }
    }
}


- (BOOL) isEqual:(id)other
{
    if (other == self) {
        return YES;
    }
    if (! other || ! [other isKindOfClass:self.class]) {
        return NO;
    }
    return [self isEqualToLocation:other];
}


- (BOOL) isEqualToLocation:(Location *)other
{
    if (self == other) {
        return YES;
    }

    if ((self.name    != other.name   ) && (! [self.name    isEqualToString: other.name   ])) { return NO; }
    if ((self.address != other.address) && (! [self.address isEqualToString: other.address])) { return NO; }

    return YES;
}


@end
