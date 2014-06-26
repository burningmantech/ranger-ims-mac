////
// DataStoreProtocol.h
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

@class Incident;


@protocol DataStoreDelegate <NSObject>


- (void) dataStore:(id)dataStore didUpdateLinks:(NSArray *)links;
- (void) dataStore:(id)dataStore willUpdateIncidentNumbered:(NSNumber *)number;
- (void) dataStore:(id)dataStore didUpdateIncident:(Incident *)incident;
- (void) dataStore:(id)dataStore didReplaceIncidentNumbered:(NSNumber *)oldNumber withIncidentNumbered:(NSNumber *)newNumber;
- (void) dataStoreDidUpdateIncidents:(id)dataStore;

- (NSURLCredential *) credentialForChallenge:(NSURLAuthenticationChallenge *)challenge;


@end



@protocol DataStoreProtocol <NSObject>


@property (strong,readonly) NSArray      *allIncidentTypes;
@property (strong,readonly) NSDictionary *allRangersByHandle;
@property (strong,readonly) NSArray      *allLocationNames;

@property (unsafe_unretained) id <DataStoreDelegate> delegate;


- (void) load;

- (NSArray *) incidents;
- (Incident *) incidentWithNumber:(NSNumber *)number;

- (Incident *) createNewIncident;
- (void) updateIncident:(Incident *)incident;
- (void) loadIncidentNumber:(NSNumber *)number;

- (NSArray *) addressesForLocationName:(NSString *)locationName;


@end
