////
// Ranger.h
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



@interface Ranger : NSObject


@property (strong) NSString *handle;
@property (strong) NSString *name;


+ (Ranger *) rangerFromJSON:(NSDictionary *)jsonRanger
                      error:(NSError **)error;

- (id) initWithHandle:(NSString *)handle
                 name:(NSString *)name;


- (BOOL) isEqualToRanger:(Ranger *)other;


@end
