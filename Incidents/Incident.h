////
// Incident.h
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
#import "DataStoreProtocol.h"

@class Ranger;
@class Location;
@class ReportEntry;
@class DispatchQueue;


typedef NS_ENUM(NSUInteger, IncidentState) {
    kIncidentStateNew,
    kIncidentStateOnHold,
    kIncidentStateDispatched,
    kIncidentStateOnScene,
    kIncidentStateClosed,
};


@interface Incident : NSObject <NSCopying>


@property (weak) id <DataStoreProtocol> dataStore;

@property (strong)   NSNumber       *number;
@property (strong)   NSDictionary   *rangersByHandle;
@property (strong)   Location       *location;
@property (strong)   NSMutableArray *types;
@property (strong)   NSString       *summary;
@property (strong)   NSArray        *reportEntries;
@property (strong)   NSNumber       *state;
@property (readonly) NSNumber       *stateName;
@property (strong)   NSNumber       *priority;
@property (readonly) NSNumber       *priorityName;


+ (Incident *) incidentInDataStore:(id <DataStoreProtocol>)dataStore
                          fromJSON:(NSDictionary *)jsonIncident error:(NSError **)error;


- (id) initInDataStore:(id <DataStoreProtocol>)dataStore
            withNumber:(NSNumber *)number;
- (id) initInDataStore:(id <DataStoreProtocol>)dataStore
            withNumber:(NSNumber *)number
               rangers:(NSArray  *)rangers
              location:(Location *)location
                 types:(NSArray  *)types
               summary:(NSString *)summary
         reportEntries:(NSArray  *)reportEntries
                 state:(NSNumber *)state
              priority:(NSNumber *)priority;

- (BOOL) isEqualToIncident:(Incident *)other;

- (BOOL) isNew;

- (NSDictionary *) asJSON;

- (void) addRanger:(Ranger *)ranger;
- (void) removeRanger:(Ranger *)ranger;

- (NSUInteger) addEntryToReport:(ReportEntry *)entry;

- (NSString *) summaryFromReport;
- (NSString *) summaryOfRangers;
- (NSString *) summaryOfTypes;


@end
