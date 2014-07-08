////
// DispatchQueueController.m
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
#import "Location.h"
#import "ReportEntry.h"
#import "Incident.h"
#import "TableView.h"
#import "AppDelegate.h"
#import "IncidentController.h"
#import "DispatchQueueController.h"



NSString *formattedDateTimeLong(NSDate *date);
NSString *formattedDateTimeShort(NSDate *date);



@interface DispatchQueueController ()
<
    NSWindowDelegate,
    NSTableViewDataSource,
    NSTableViewDelegate,
    TableViewDelegate,
    DataStoreDelegate
>

@property (weak) AppDelegate *appDelegate;

@property (weak) IBOutlet NSSearchField       *searchField;
@property (weak) IBOutlet NSTableView         *dispatchTable;
@property (weak) IBOutlet NSProgressIndicator *loadingIndicator;
@property (weak) IBOutlet NSButton            *reloadButton;
@property (weak) IBOutlet NSButton            *showClosed;
@property (weak) IBOutlet NSTextField         *updatedLabel;

@property (strong,nonatomic) NSArray *sortedIncidents;
@property (strong,nonatomic) NSArray *sortedOpenIncidents;
@property (strong,nonatomic) NSArray *filteredIncidents;
@property (strong,nonatomic) NSArray *filteredIncidentsKey;

@property (strong,nonatomic) NSMutableDictionary *incidentControllersToReplace;

@property (assign) NSInteger reloadInterval;
@property (strong) NSTimer *reloadTimer;
@property (strong) NSDate *lastLoadedDate;

@end



@implementation DispatchQueueController


- (id) initWithDataStore:(id <DataStoreProtocol>)dataStore
             appDelegate:(AppDelegate *)appDelegate
{
    if (self = [super initWithWindowNibName:@"DispatchQueueController"]) {
        dataStore.delegate = self;

        self.dataStore = dataStore;
        self.appDelegate = appDelegate;
        self.incidentControllers = [NSMutableDictionary dictionary];
        self.sortedIncidents = nil;
        self.sortedOpenIncidents = nil;
        self.filteredIncidents = nil;
        self.filteredIncidentsKey = @[];
        self.incidentControllersToReplace = [NSMutableDictionary dictionary];
        self.reloadTimer = nil;
        self.lastLoadedDate = [NSDate distantPast];
    }
    return self;
}


- (void) windowDidLoad
{
    [super windowDidLoad];

    NSButton *reloadButton = self.reloadButton;
    reloadButton.hidden = NO;

    NSProgressIndicator *loadingIndicator = self.loadingIndicator;
    loadingIndicator.hidden = YES;

    NSTableView *dispatchTable = self.dispatchTable;
    dispatchTable.doubleAction = @selector(openClickedIncident);
    
    [self load];
}


- (void) startLoadTimerWithInterval:(NSTimeInterval)interval
{
    if (! self.reloadTimer || ! self.reloadTimer.isValid) {
        self.reloadTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                            target:self
                                                          selector:NSSelectorFromString(@"reload:")
                                                          userInfo:nil
                                                           repeats:NO];
    }
}


- (NSInteger) reloadInterval
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger interval = [defaults integerForKey:@"IMSPollInterval"];

    if (interval < 8) {
        if (interval != 0) {
            NSLog(@"ERROR: Unfortunate value for reload interval: %ld", interval);
        }
        interval = 10; // default value
        self.reloadInterval = interval;
    }

    return interval;
}


- (void) setReloadInterval:(NSInteger)interval
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (interval == 0) {
        // Revert to default value
        [defaults removeObjectForKey:@"IMSPollInterval"];
        return;
    }

    if (interval < 8) {
        NSLog(@"ERROR: reload interval may not be < 8. Got: %ld", interval);
        interval = 8;
    }

    [defaults setInteger:interval forKey:@"IMSPollInterval"];
}


- (void) load
{
    NSLog(@"Updating dispatch queue...");
    
    // Load queue data from server
    [self.dataStore load];
}


- (void) loadTable
{
    self.sortedIncidents = nil;
    self.sortedOpenIncidents = nil;
    self.filteredIncidents = nil;
    self.filteredIncidentsKey = @[];

    NSTableView *dispatchTable = self.dispatchTable;
    if (dispatchTable) {
        //[dispatchTable noteNumberOfRowsChanged];
        [dispatchTable reloadData];
    }
    else {
        performAlert(@"dispatchTable is not connected.");
    }
}


- (Incident *) selectedIncident {
    NSTableView *dispatchTable = self.dispatchTable;
    NSInteger rowIndex = dispatchTable.selectedRow;

    return [self incidentForTableRow:rowIndex];
}


- (void) openSelectedIncident:(id)sender
{
    [self openIncident:[self selectedIncident]];
}


- (void) openClickedIncident
{
    NSTableView *dispatchTable = self.dispatchTable;
    NSInteger rowIndex = dispatchTable.clickedRow;
    Incident *incident = [self incidentForTableRow:rowIndex];

    [self openIncident:incident];
}


- (void) openNewIncident:(id)sender
{
    Incident *incident = [self.dataStore createNewIncident];

    if (! incident) {
        performAlert(@"Unable to create new incident?");
        return;
    }

    [self openIncident:incident];
}


- (void) openIncident:(Incident *)incident
{
    if (! incident) {
        return;
    }

    // See if we already have an open controller for this incident
    IncidentController *incidentController = self.incidentControllers[incident.number];

    // …or create one if necessary.
    if (! incidentController) {
        incidentController = [[IncidentController alloc] initWithDispatchQueueController:self
                                                                                incident:[incident copy]];

        self.incidentControllers[incident.number] = incidentController;
    }

    [incidentController showWindow:self];
    [incidentController.window makeKeyAndOrderFront:self];

    void (^incidentWindowDidClose)(NSNotification *) = ^(NSNotification *notification) {
        NSWindow *notedWindow = notification.object;
        IncidentController *notedController = notedWindow.windowController;
        Incident *notedIncident = notedController.incident;

        if (notedController != incidentController) {
            performAlert(@"Closing incident controllers don't match: %@ != %@", notedController, incidentController);
        }
        if (incident.number.integerValue > 0 && ! [notedIncident.number isEqualToNumber:incident.number]) {
            performAlert(@"Closing incidents don't match: %@ != %@", notedIncident.number, incident.number);
        }

        [self.incidentControllers removeObjectForKey:incident.number];
    };

    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification
                                                      object:incidentController.window
                                                       queue:nil
                                                  usingBlock:incidentWindowDidClose];
}


- (NSArray *) sortedIncidents {
    NSSearchField *searchField = self.searchField;
    NSSearchFieldCell *searchFieldCell = searchField.cell;
    NSString *searchText = searchFieldCell.stringValue;
    NSButton *showClosed = self.showClosed;
    NSArray *filteredIncidentsKey = @[searchText, self.showClosed];

    if ([self.filteredIncidentsKey isEqualToArray:filteredIncidentsKey]) {
        return self.filteredIncidents;
    }
    
    if (! _sortedIncidents) {
        // FIXME: If the table has no sort descriptors,
        // default to something useful.

        NSTableView *dispatchTable = self.dispatchTable;
        _sortedIncidents =
            [self.dataStore.incidents sortedArrayUsingDescriptors:dispatchTable.sortDescriptors];
    }

    if (! _sortedOpenIncidents) {
        BOOL(^openFilter)(Incident *, NSDictionary *) = ^(Incident *incident, NSDictionary *bindings) {
            if (incident.closed) { return NO ; }
            else                 { return YES; }
        };
        NSPredicate *openPredicate = [NSPredicate predicateWithBlock:openFilter];
        _sortedOpenIncidents = [_sortedIncidents filteredArrayUsingPredicate:openPredicate];
    }

    NSArray *result;
    if (showClosed.state == NSOffState) {
        result = _sortedOpenIncidents;
    }
    else {
        result = _sortedIncidents;
    }

    if (searchText.length) {
        BOOL(^searchFilter)(Incident *, NSDictionary *) = ^(Incident *incident, NSDictionary *bindings) {
            //
            // Set up an array of sources that we will search in
            //
            NSMutableArray *sources = [NSMutableArray array];

            if (incident.summary         ) [sources addObject:incident.summary         ];
            if (incident.location.name   ) [sources addObject:incident.location.name   ];
            if (incident.location.address) [sources addObject:incident.location.address];

            for (NSArray *array in @[
                incident.rangersByHandle.allKeys,
                incident.types,
            ]) {
                for (NSString *rangerHandle in array) {
                    [sources addObject:rangerHandle];
                }
            }

            for (ReportEntry *entry in incident.reportEntries) {
                [sources addObject:entry.text];
            }

            //
            // Tokeninze the seach field text
            //
            NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
            NSArray *tokens = [searchText componentsSeparatedByCharactersInSet:whiteSpace];

            //
            // Search sources for each token
            //
            for (NSString *token in tokens) {
                if (token.length == 0) {
                    continue;
                }

                BOOL found = NO;

                for (NSString *source in sources) {
                    if (source) {
                        NSRange range = [source rangeOfString:token options:NSCaseInsensitiveSearch];
                        if (range.location != NSNotFound && range.length != 0) {
                            found = YES;
                        }
                    }
                }

                if (! found) {
                    return NO;
                }
            }
            return YES;
        };
        NSPredicate *searchPredicate = [NSPredicate predicateWithBlock:searchFilter];
        result = [result filteredArrayUsingPredicate:searchPredicate];
    }

    self.filteredIncidentsKey = filteredIncidentsKey;
    self.filteredIncidents = result;
    
    return result;
}


- (Incident *) incidentForTableRow:(NSInteger)rowIndex {
    NSArray *incidents = self.sortedIncidents;

    if (rowIndex < 0) {
        return nil;
    }

    if (rowIndex >= (NSInteger)incidents.count) {
        NSLog(@"incidentForTableRow: got out of bounds rowIndex: %ld", rowIndex);
        return nil;
    }
    
    return incidents[(NSUInteger)rowIndex];
}


- (IBAction) reload:(id)sender
{
    [self load];
}


- (IBAction) loadTable:(id)sender
{
    [self loadTable];
}


- (void) findIncident:(id)sender
{
    [self.window makeKeyAndOrderFront:self];
    [self.window makeFirstResponder:self.searchField];
}


////
// DataStoreDelegate methods
////


- (void) dataStore:(id)dataStore didUpdateLinks:(NSArray *)links
{
    AppDelegate *appDelegate = self.appDelegate;
    [appDelegate updateLinks:links];
}


- (void) dataStore:(id)dataStore willUpdateIncidentNumbered:(NSNumber *)number;
{
    // Hide the reload button…
    NSButton *reloadButton = self.reloadButton;
    reloadButton.hidden = YES;

    // Spin the progress indicator...
    NSProgressIndicator *loadingIndicator = self.loadingIndicator;
    loadingIndicator.hidden = NO;
    [loadingIndicator startAnimation:self];

    // Display the update time
    NSTextField *updatedLabel = self.updatedLabel;
    updatedLabel.stringValue = [NSString stringWithFormat:@"Updating incident #%@…", number];
}


- (void) dataStoreDidUpdateIncidents:(id)dataStore
{
    self.lastLoadedDate = [NSDate date];

    // Stop the progress indicator.
    NSProgressIndicator *loadingIndicator = self.loadingIndicator;
    [loadingIndicator stopAnimation:self];
    loadingIndicator.hidden = YES;

    // Show the reload button…
    NSButton *reloadButton = self.reloadButton;
    reloadButton.hidden = NO;

    // Display the update time
    NSTextField *updatedLabel = self.updatedLabel;
    updatedLabel.stringValue = [NSString stringWithFormat: @"Last updated: %@", formattedDateTimeLong(self.lastLoadedDate)];

    [self startLoadTimerWithInterval:(NSTimeInterval)self.reloadInterval];
}


- (void) dataStore:(id)dataStore didUpdateIncident:(Incident *)incident
{
    NSButton *showClosed = self.showClosed;

    // Only reload the table if the updated incident would be displayed.
    // That means "show closed" is enabled, or the incident is still open
    if (showClosed.state != NSOffState || ! incident.closed) {
        [self loadTable];
    }

    // Check for an existing controller with a temporary (new) incident that needs to be replaced
    IncidentController *controller = self.incidentControllersToReplace[incident.number];
    if (controller) {
        // Update the controller with the new incident
        controller.incident = [incident copy];
        [controller updateIncident];

        // Add to known controllers
        self.incidentControllers[incident.number] = controller;
    }
    else {
        controller = self.incidentControllers[incident.number];
        if (controller) {
            controller.incident = [incident copy];
            [controller updateIncident];
        }
    }
}


- (void) dataStore:(id)dataStore didReplaceIncidentNumbered:(NSNumber *)oldNumber withIncidentNumbered:(NSNumber *)newNumber
{
    IncidentController *controller = self.incidentControllers[oldNumber];
    if (controller) {
        // This number is no longer valid; remove from cache.
        [self.incidentControllers removeObjectForKey:oldNumber];

        self.incidentControllersToReplace[newNumber] = controller;
    }
}


- (NSURLCredential *) credentialForChallenge:(NSURLAuthenticationChallenge *)challenge
{
    AppDelegate *appDelegate = self.appDelegate;
    return [appDelegate credentialForChallenge:challenge];
}


@end



@implementation DispatchQueueController (NSTableViewDataSource)


- (NSUInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.sortedIncidents.count;
}


- (id)            tableView:(NSTableView *)tableView
  objectValueForTableColumn:(NSTableColumn *)column
                        row:(NSInteger)rowIndex
{
    Incident *incident = [self incidentForTableRow:rowIndex];

    if (! incident) {
        NSLog(@"Invalid table row: %ld", rowIndex);
        return nil;
    }
    
    NSString *identifier = [column identifier];

    if ([identifier isEqualToString:@"number"]) {
        return incident.number;
    }
    else if ([identifier isEqualToString:@"priority"]) {
        return incident.priority;
    }
    else if ([identifier isEqualToString:@"created"]) {
        return formattedDateTimeShort(incident.created);
    }
    else if ([identifier isEqualToString:@"dispatched"]) {
        return formattedDateTimeShort(incident.dispatched);
    }
    else if ([identifier isEqualToString:@"onScene"]) {
        return formattedDateTimeShort(incident.onScene);
    }
    else if ([identifier isEqualToString:@"closed"]) {
        return formattedDateTimeShort(incident.closed);
    }
    else if ([identifier isEqualToString:@"rangers"]) {
        return incident.summaryOfRangers;
    }
    else if ([identifier isEqualToString:@"location"]) {
        return incident.location.description;
    }
    else if ([identifier isEqualToString:@"locationName"]) {
        return incident.location.name;
    }
    else if ([identifier isEqualToString:@"locationAddress"]) {
        return incident.location.address;
    }
    else if ([identifier isEqualToString:@"types"]) {
        return [self joinedStrings:incident.types withSeparator:@", "];
    }
    else if ([identifier isEqualToString:@"summary"]) {
        return incident.summaryFromReport;
    }

    performAlert(@"Unknown column identifier: %@", identifier);
    return nil;
}


- (NSString*) joinedStrings:(NSArray*)strings withSeparator:(NSString*)separator
{
//    return [strings componentsJoinedByString:separator];

    NSString *result = nil;
    for (NSString *string in strings) {
        if (result) {
            result = [result stringByAppendingString:separator];
        }
        else {
            result = @"";
        }
        result = [result stringByAppendingString:string];
    }
    return result;
}


@end



@implementation DispatchQueueController (NSTableViewDelegate)


- (void)         tableView:(NSTableView *)tableView
  sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    [self loadTable];
}


@end



@implementation DispatchQueueController (TableViewDelegate)


- (void) deleteFromTableView:(NSTableView *)tableView
{
}


- (void) openFromTableView:(NSTableView *)tableView
{
    [self openIncident:[self selectedIncident]];
}


@end



static NSDateFormatter *longDayTimeFormatter  = nil;
static NSDateFormatter *shortDayTimeFormatter = nil;

NSString *formattedDateTimeLong(NSDate *date)
{
    if (! longDayTimeFormatter) {
        longDayTimeFormatter = [[NSDateFormatter alloc] init];
        [longDayTimeFormatter setDateFormat:@"EEEE, MMMM d, yyyy HH:mm:ss zzz"];
    }
    return [longDayTimeFormatter stringFromDate:date];
}


NSString *formattedDateTimeShort(NSDate *date)
{
    if (! shortDayTimeFormatter) {
        shortDayTimeFormatter = [[NSDateFormatter alloc] init];
        [shortDayTimeFormatter setDateFormat:@"EEEEE.HH:mm"];
    }
    return [shortDayTimeFormatter stringFromDate:date];
}
