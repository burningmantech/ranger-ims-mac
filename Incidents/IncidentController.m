////
// IncidentController.m
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

#import <Block.h>
#import "utilities.h"
#import "ReportEntry.h"
#import "Incident.h"
#import "Location.h"
#import "Ranger.h"
#import "TableView.h"
#import "DispatchQueueController.h"
#import "IncidentController.h"



static NSDateFormatter *entryDateFormatter = nil;



@interface IncidentController ()
<
    NSWindowDelegate,
    NSTableViewDataSource,
    NSTableViewDelegate,
    NSTextFieldDelegate,
    TableViewDelegate
>

@property (strong) DispatchQueueController *dispatchQueueController;

@property (weak)   IBOutlet NSTextField         *numberField;
@property (weak)   IBOutlet NSPopUpButton       *statePopUp;
@property (weak)   IBOutlet NSPopUpButton       *priorityPopUp;
@property (weak)   IBOutlet NSTextField         *summaryField;
@property (weak)   IBOutlet NSTableView         *rangersTable;
@property (weak)   IBOutlet NSTextField         *rangerToAddField;
@property (weak)   IBOutlet NSTableView         *typesTable;
@property (weak)   IBOutlet NSTextField         *typeToAddField;
@property (weak)   IBOutlet NSTextField         *locationNameField;
@property (weak)   IBOutlet NSTextField         *locationAddressField;
@property (assign) IBOutlet NSTextView          *reportEntriesView;
@property (assign) IBOutlet NSTextView          *reportEntryToAddView;
@property (assign) IBOutlet NSButton            *saveButton;
@property (weak)   IBOutlet NSProgressIndicator *loadingIndicator;
@property (weak)   IBOutlet NSButton            *reloadButton;

@property (assign) BOOL stateDidChange;
@property (assign) BOOL priorityDidChange;
@property (assign) BOOL summaryDidChange;
@property (assign) BOOL rangersDidChange;
@property (assign) BOOL typesDidChange;
@property (assign) BOOL locationDidChange;
@property (assign) BOOL reportDidChange;

@property (assign) BOOL amCompleting;
@property (assign) BOOL amBackspacing;

@end



@implementation IncidentController


- (id) initWithDispatchQueueController:(DispatchQueueController *)dispatchQueueController
                              incident:(Incident *)incident
{
    if (! incident) {
        [NSException raise:NSInvalidArgumentException format:@"incident may not be nil"];
    }

    if (self = [super initWithWindowNibName:@"IncidentController"]) {
        self.dispatchQueueController = dispatchQueueController;
        self.incident = incident;
    }
    return self;
}


- (void) dealloc
{
    self.reportEntriesView    = nil;
    self.reportEntryToAddView = nil;
}


- (NSString *) summarize
{
    NSTextField   *numberField          = self.numberField;
    NSPopUpButton *statePopUp           = self.statePopUp;
    NSPopUpButton *priorityPopUp        = self.priorityPopUp;
    NSTextField   *summaryField         = self.summaryField;
    NSTextField   *rangerToAddField     = self.rangerToAddField;
    NSTextField   *typeToAddField       = self.typeToAddField;
    NSTextField   *locationNameField    = self.locationNameField;
    NSTextField   *locationAddressField = self.locationAddressField;
    NSTextView    *reportEntryToAddView = self.reportEntryToAddView;

    return [NSString stringWithFormat:
            @"------------------------------\n"
            @"Incident: %@\n"
            @"------------------------------\n"
            @"FIELDS:\n"
            @"  Number: %@\n"
            @"  State: %@\n"
            @"  Priority: %@\n"
            @"  Summary: %@\n"
            @"  Ranger to add: %@\n"
            @"  Type to add: %@\n"
            @"  Location name: %@\n"
            @"  Location address: %@\n"
            @"  Entry to add: %@\n"
            @"------------------------------\n"
            @"CHANGED:\n"
            @"  State: %@\n"
            @"  Priority: %@\n"
            @"  Summary: %@\n"
            @"  Rangers: %@\n"
            @"  Types: %@\n"
            @"  Location: %@\n"
            @"  Entry: %@\n"
            @"------------------------------\n"
            ,

            self.incident,

            numberField.stringValue,
            statePopUp.stringValue,
            priorityPopUp.stringValue,
            summaryField.stringValue,
            rangerToAddField.stringValue,
            typeToAddField.stringValue,
            locationNameField.stringValue,
            locationAddressField.stringValue,
            reportEntryToAddView.textStorage.string,

            self.stateDidChange    ? @"YES" : @"NO",
            self.priorityDidChange ? @"YES" : @"NO",
            self.summaryDidChange  ? @"YES" : @"NO",
            self.rangersDidChange  ? @"YES" : @"NO",
            self.typesDidChange    ? @"YES" : @"NO",
            self.locationDidChange ? @"YES" : @"NO",
            self.reportDidChange   ? @"YES" : @"NO"];
}


- (void) windowDidLoad
{
    [super windowDidLoad];

    [self updateIncident];
}


- (void) clearChangeTracking
{
    self.stateDidChange    = NO;
    self.priorityDidChange = NO;
    self.summaryDidChange  = NO;
    self.rangersDidChange  = NO;
    self.typesDidChange    = NO;
    self.locationDidChange = NO;
    self.reportDidChange   = NO;

    self.window.documentEdited = NO;
}


- (void) enableEditing
{
    NSPopUpButton *statePopUp           = self.statePopUp;
    NSPopUpButton *priorityPopUp        = self.priorityPopUp;
    NSTextField   *summaryField         = self.summaryField;
    NSTableView   *rangersTable         = self.rangersTable;
    NSTextField   *rangerToAddField     = self.rangerToAddField;
    NSTableView   *typesTable           = self.typesTable;
    NSTextField   *typeToAddField       = self.typeToAddField;
    NSTextField   *locationNameField    = self.locationNameField;
    NSTextField   *locationAddressField = self.locationAddressField;
    NSTextView    *reportEntriesView    = self.reportEntriesView;
    NSTextView    *reportEntryToAddView = self.reportEntryToAddView;
    NSButton      *saveButton           = self.saveButton;

    [statePopUp           setEnabled: YES];
    [priorityPopUp        setEnabled: YES];
    [summaryField         setEnabled: YES];
    [rangersTable         setEnabled: YES];
    [rangerToAddField     setEnabled: YES];
    [typesTable           setEnabled: YES];
    [typeToAddField       setEnabled: YES];
    [locationNameField    setEnabled: YES];
    [locationAddressField setEnabled: YES];
    [reportEntriesView    setEditable:YES];
    [reportEntryToAddView setEditable:YES];
    [saveButton           setEnabled: YES];
}


- (void) disableEditing
{
    NSPopUpButton *statePopUp           = self.statePopUp;
    NSPopUpButton *priorityPopUp        = self.priorityPopUp;
    NSTextField   *summaryField         = self.summaryField;
    NSTableView   *rangersTable         = self.rangersTable;
    NSTextField   *rangerToAddField     = self.rangerToAddField;
    NSTableView   *typesTable           = self.typesTable;
    NSTextField   *typeToAddField       = self.typeToAddField;
    NSTextField   *locationNameField    = self.locationNameField;
    NSTextField   *locationAddressField = self.locationAddressField;
    NSTextView    *reportEntriesView    = self.reportEntriesView;
    NSTextView    *reportEntryToAddView = self.reportEntryToAddView;
    NSButton      *saveButton           = self.saveButton;

    [statePopUp           setEnabled: NO];
    [priorityPopUp        setEnabled: NO];
    [summaryField         setEnabled: NO];
    [rangersTable         setEnabled: NO];
    [rangerToAddField     setEnabled: NO];
    [typesTable           setEnabled: NO];
    [typeToAddField       setEnabled: NO];
    [locationNameField    setEnabled: NO];
    [locationAddressField setEnabled: NO];
    [reportEntriesView    setEditable:NO];
    [reportEntryToAddView setEditable:NO];
    [saveButton           setEnabled: NO];
}


- (IBAction) markClosedAndSave:(id)sender
{
    NSPopUpButton *statePopUp = self.statePopUp;
    NSInteger stateTag = statePopUp.selectedItem.tag;

    if (stateTag != 4) {
        [statePopUp selectItemWithTag:4];
        [self editState:self];
    }

    [self save:self];
    [self.window performClose:self];
}


- (IBAction) reload:(id)sender
{
    if (self.incident.isNew) {
        return; // Nothing to reload
    }

    // Hide the reload button…
    NSButton *reloadButton = self.reloadButton;
    reloadButton.hidden = YES;

    // Spin the progress indicator...
    NSProgressIndicator *loadingIndicator = self.loadingIndicator;
    loadingIndicator.hidden = NO;
    [loadingIndicator startAnimation:self];

    [self.dispatchQueueController.dataStore loadIncidentNumber:self.incident.number];
}


- (void) updateIncident
{
    if (! self.incident.isNew) {
        self.incident = [[self.dispatchQueueController.dataStore incidentWithNumber:self.incident.number] copy];
    }

    [self updateView];
    [self clearChangeTracking];
    [self enableEditing];

    // Stop the progress indicator.
    NSProgressIndicator *loadingIndicator = self.loadingIndicator;
    [loadingIndicator stopAnimation:self];
    loadingIndicator.hidden = YES;

    // Show the reload button…
    NSButton *reloadButton = self.reloadButton;
    reloadButton.hidden = NO;

    if (self.incident.isNew) {
        [reloadButton setEnabled: NO];
    }
    else {
        [reloadButton setEnabled: YES];
    }
}


- (void) updateView
{
    Incident *incident = self.incident;

    //NSLog(@"Displaying: %@", incident);

    NSString *summaryFromReport = incident.summaryFromReport;

    NSString *numberToDisplay;
    if (incident.isNew) {
        numberToDisplay = @"(new)";
    } else {
        numberToDisplay = incident.number.stringValue;
    }

    if (self.window) {
        self.window.title = [NSString stringWithFormat:
                                @"%@: %@",
                                numberToDisplay,
                                summaryFromReport];
    }
    else {
        performAlert(@"No window?");
    }

    NSTextField *numberField = self.numberField;
    if (numberField) {
        numberField.stringValue = numberToDisplay;
    }
    else {
        performAlert(@"No numberField?");
    }

    NSPopUpButton *statePopUp = self.statePopUp;
    if (statePopUp) {
        NSInteger stateTag;

        if      (incident.closed    ) { stateTag = 4; }
        else if (incident.onScene   ) { stateTag = 3; }
        else if (incident.dispatched) { stateTag = 2; }
        else if (incident.created   ) { stateTag = 1; }
        else {
            performAlert(@"Unknown incident state.");
            stateTag = 0;
        }
        [statePopUp selectItemWithTag:stateTag];

        void (^enableState)(NSInteger, BOOL) = ^(NSInteger tag, BOOL enabled) {
            [[statePopUp itemAtIndex: [statePopUp indexOfItemWithTag:tag]] setEnabled:enabled];
        };

        void (^enableStates)(BOOL, BOOL, BOOL, BOOL) = ^(BOOL one, BOOL two, BOOL three, BOOL four) {
            enableState(1, one);
            enableState(2, two);
            enableState(3, three);
            enableState(4, four);
        };

        if      (stateTag == 1) { enableStates(YES, YES, YES, YES); }
        else if (stateTag == 2) { enableStates(YES, YES, YES, YES); }
        else if (stateTag == 3) { enableStates(NO , YES, YES, YES); }
        else if (stateTag == 4) { enableStates(YES, NO , NO , YES); }
    }
    else {
        performAlert(@"No statePopUp?");
    }

    NSPopUpButton *priorityPopUp = self.priorityPopUp;
    if (priorityPopUp) {
        [priorityPopUp selectItemWithTag:incident.priority.integerValue];
    }
    else {
        performAlert(@"No priorityPopUp?");
    }

    NSTextField *summaryField = self.summaryField;
    if (summaryField) {
        if (incident.summary && incident.summary.length) {
            summaryField.stringValue = incident.summary;
        }
        else {
            if (! [summaryField.stringValue isEqualToString:@""]) {
                summaryField.stringValue = @"";
            }
            if (! [[summaryField.cell placeholderString] isEqualToString:summaryFromReport]) {
                [summaryField.cell setPlaceholderString:summaryFromReport];
            }
        }
    }
    else {
        performAlert(@"No summaryField?");
    }

    NSTableView *rangersTable = self.rangersTable;
    if (rangersTable) {
        [rangersTable reloadData];
    }
    else {
        performAlert(@"No rangersTable?");
    }

    NSTableView *typesTable = self.typesTable;
    if (typesTable) {
        [typesTable reloadData];
    }
    else {
        performAlert(@"No typesTable?");
    }

    NSTextField *locationNameField = self.locationNameField;
    if (locationNameField) {
        locationNameField.stringValue = incident.location.name ? incident.location.name : @"";
    }
    else {
        performAlert(@"No locationNameField?");
    }

    NSTextField *locationAddressField = self.locationAddressField;
    if (locationAddressField) {
        locationAddressField.stringValue = incident.location.address ? incident.location.address : @"";
    }
    else {
        performAlert(@"No locationAddressField?");
    }

    NSTextView *reportEntriesView = self.reportEntriesView;
    if (reportEntriesView) {
        [reportEntriesView.textStorage
            setAttributedString:[self formattedReport]];

        NSRange end = NSMakeRange([[reportEntriesView string] length],0);
        [reportEntriesView scrollRangeToVisible:end];
    }
    else {
        performAlert(@"No reportEntriesView?");
    }
}


- (void) commitIncident
{
    if (self.incident.isNew) {
        // New incident
        [self disableEditing];
        [self.dispatchQueueController.dataStore updateIncident:self.incident];
    }
    else {
        // Edited incident
        BOOL edited = NO;

        NSArray  *rangers    = nil; if (self.rangersDidChange  ) { edited = YES; rangers    = self.incident.rangersByHandle.allValues; }
        NSArray  *types      = nil; if (self.typesDidChange    ) { edited = YES; types      = self.incident.types;                     }
        NSString *summary    = nil; if (self.summaryDidChange  ) { edited = YES; summary    = self.incident.summary;                   }
        NSDate   *created    = nil; if (self.stateDidChange    ) { edited = YES; created    = self.incident.created;                   }
        NSDate   *dispatched = nil; if (self.stateDidChange    ) { edited = YES; dispatched = self.incident.dispatched;                }
        NSDate   *onScene    = nil; if (self.stateDidChange    ) { edited = YES; onScene    = self.incident.onScene;                   }
        NSDate   *closed     = nil; if (self.stateDidChange    ) { edited = YES; closed     = self.incident.closed;                    }
        NSNumber *priority   = nil; if (self.priorityDidChange ) { edited = YES; priority   = self.incident.priority;                  }

        Location *location = nil;
        if (self.locationDidChange) {
            edited = YES;
            location = [[Location alloc] initWithName:self.incident.location.name
                                              address:self.incident.location.address];
        }

        NSArray *reportEntries = nil;
        if (self.reportDidChange) {
            edited = YES;
            reportEntries = @[self.incident.reportEntries.lastObject];
        }

        if (edited) {
            [self disableEditing];

            Incident *incidentToCommit = [[Incident alloc] initInDataStore:self.incident.dataStore
                                                                withNumber:self.incident.number
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

            [self.dispatchQueueController.dataStore updateIncident:incidentToCommit];
        }
    }
}


- (NSAttributedString *) formattedReport
{
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:@""];

    for (ReportEntry *entry in self.incident.reportEntries) {
        NSAttributedString *text = [self formattedReportEntry:entry];
        [result appendAttributedString:text];
    }

    return result;
}


- (NSAttributedString *) formattedReportEntry:(ReportEntry *)entry
{
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:@""];

    // Prepend a date stamp.
    NSAttributedString *dateStamp = [self dateStampForReportEntry:entry];

    [result appendAttributedString:dateStamp];

    // Append the entry text.
    NSAttributedString *text = [self textForReportEntry:entry];

    [result appendAttributedString:text];
    [result appendAttributedString:newline];

    // Add (another) newline if text didn't end in newline
    NSUInteger length = [text length];
    unichar lastCharacter = [[text string] characterAtIndex:length-1];

    if (lastCharacter != '\n') {
        [result appendAttributedString:newline];
    }

    return result;
}


- (NSAttributedString *) dateStampForReportEntry:(ReportEntry *)entry
{
    if (!entryDateFormatter) {
        entryDateFormatter = [[NSDateFormatter alloc] init];
        [entryDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    }

    NSString *dateFormatted = [entryDateFormatter stringFromDate:entry.createdDate];
    NSString *dateStamp = [NSString stringWithFormat:@"%@, %@:\n", dateFormatted, entry.author];

    NSString *fontName = @"Verdana-Bold";
    CGFloat fontSize = 10.0;
    NSColor *textColor = [NSColor textColor];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];

    if (entry.systemEntry) {
        textColor = [textColor colorWithAlphaComponent:0.5];
        paragraphStyle.alignment = NSCenterTextAlignment;
    }

    NSDictionary *attributes = @{
        NSFontAttributeName           : [NSFont fontWithName:fontName size:fontSize],
        NSForegroundColorAttributeName: textColor,
        NSParagraphStyleAttributeName : paragraphStyle,
    };

    return [[NSAttributedString alloc] initWithString:dateStamp
                                           attributes:attributes];
}


- (NSAttributedString *) textForReportEntry:(ReportEntry *)entry
{
    NSString *fontName = @"Verdana";
    CGFloat fontSize = 12.0;
    NSColor *textColor = [NSColor textColor];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];

    if (entry.systemEntry) {
        fontSize -= 2.0;
        textColor = [textColor colorWithAlphaComponent:0.5];
        paragraphStyle.alignment = NSCenterTextAlignment;
    }

    NSDictionary *attributes = @{
        NSFontAttributeName           : [NSFont fontWithName:fontName size:fontSize],
        NSForegroundColorAttributeName: textColor,
        NSParagraphStyleAttributeName : paragraphStyle,
    };

    NSAttributedString *text = [[NSAttributedString alloc] initWithString:entry.text
                                                               attributes:attributes];

    return text;
}


- (IBAction) save:(id)sender
{
    // Flush the text fields
    [self editSummary:self];
    [self editLocationName:self];
    [self editLocationAddress:self];

    // Get any added report text
    NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSTextView *reportEntryToAddView = self.reportEntryToAddView;
    NSString* reportTextToAdd = reportEntryToAddView.textStorage.string;
    reportTextToAdd = [reportTextToAdd stringByTrimmingCharactersInSet:whiteSpace];

    // Add a report entry
    if (reportTextToAdd.length > 0) {
        ReportEntry *entry = [[ReportEntry alloc] initWithText:reportTextToAdd];
        [self.incident addEntryToReport:entry];

        self.reportDidChange = YES;
        self.window.documentEdited = YES;
    }

    // Commit the change
    [self commitIncident];

    // Clear the report entry view
    reportEntryToAddView.textStorage.attributedString = [[NSAttributedString alloc] initWithString:@""];
}


- (IBAction) editSummary:(id)sender
{
    Incident *incident = self.incident;
    NSTextField *summaryField = self.summaryField;
    NSString *summary = summaryField.stringValue;

    if (! [summary isEqualToString:incident.summary ? incident.summary : @""]) {
        incident.summary = summary;
        self.summaryDidChange = YES;
        self.window.documentEdited = YES;
    }
}


- (IBAction) editState:(id)sender
{
    Incident *incident = self.incident;
    NSPopUpButton *statePopUp = self.statePopUp;
    NSInteger stateTag = statePopUp.selectedItem.tag;

    if (stateTag == 1) {
        if (incident.dispatched || incident.onScene || incident.closed) {
            self.stateDidChange = YES;
            incident.dispatched = nil;
            incident.onScene    = nil;
            incident.closed     = nil;
        }
    }
    else if (stateTag == 2) {
        if (! incident.dispatched) {
            self.stateDidChange = YES;
            incident.dispatched = [NSDate date];
        }

        if (incident.onScene || incident.closed) {
            self.stateDidChange = YES;
            incident.onScene = nil;
            incident.closed  = nil;
        }
    }
    else if (stateTag == 3) {
        if (! incident.dispatched) {
            self.stateDidChange = YES;
            incident.dispatched = [NSDate date];
        }

        if (! incident.onScene) {
            self.stateDidChange = YES;
            incident.onScene = [NSDate date];
        }

        if (incident.closed) {
            self.stateDidChange = YES;
            incident.closed = nil;
        }
    }
    else if (stateTag == 4) {
        if (! incident.dispatched) {
            self.stateDidChange = YES;
            incident.dispatched = [NSDate date];
        }

        if (! incident.onScene) {
            self.stateDidChange = YES;
            incident.onScene = [NSDate date];
        }

        if (! incident.closed) {
            self.stateDidChange = YES;
            incident.closed = [NSDate date];
        }
    }
    else {
        performAlert(@"Unknown state tag: %ld", stateTag);
        return;
    }

    self.window.documentEdited = YES;
}


- (IBAction) editPriority:(id)sender
{
    Incident *incident = self.incident;
    NSPopUpButton *priorityPopUp = self.priorityPopUp;
    NSNumber *priority = [NSNumber numberWithInteger:priorityPopUp.selectedItem.tag];

    if (! [priority isEqualToNumber:incident.priority]) {
        NSLog(@"Priority edited.");
        incident.priority = priority;
        self.priorityDidChange = YES;
        self.window.documentEdited = YES;
    }
}


- (IBAction) editLocationName:(id)sender
{
    Incident *incident = self.incident;
    NSTextField *locationNameField = self.locationNameField;
    NSString *locationName = locationNameField.stringValue;

    if (! [locationName isEqualToString:incident.location.name ? incident.location.name : @""]) {
        NSLog(@"Location name edited.");

        if (! incident.location) {
            incident.location = [[Location alloc] initWithName:nil address:nil];
        }

        incident.location.name = locationName;
        self.locationDidChange = YES;
        self.window.documentEdited = YES;

        if (locationName.length > 0) {
            NSTextField *locationAddressField = self.locationAddressField;

            if (locationAddressField.stringValue.length == 0) {
                NSArray *addresses = [self.dispatchQueueController.dataStore
                                      addressesForLocationName:locationName];

                //
                // Note that when we fill in the address field, we do *not* call -editLocationAddress:
                // here, because we want to let the user modify or clear the field back out if desired
                // before a change to the address value is noted.
                //
                if (addresses.count == 1) {
                    // Only one result (yay!), fill it in
                    locationAddressField.stringValue = addresses[0];
                    [locationAddressField selectText:self];
                }
                else if (addresses.count > 1) {
                    // Put "?" in the address field to cause all completetions to trigger
                    locationAddressField.stringValue = @"?";

                    // Select the address text
                    [locationAddressField selectText:self];

                    // Ask the field editor to complete the text
                    NSText *fieldEditor = [self.window fieldEditor:YES forObject:locationAddressField];
                    self.amCompleting = YES;
                    [fieldEditor complete:self];
                    self.amCompleting = NO;
                }
            }
        }
    }
}


- (IBAction) editLocationAddress:(id)sender
{
    Incident *incident = self.incident;
    NSTextField *locationAddressField = self.locationAddressField;
    NSString *locationAddress = locationAddressField.stringValue;

    if (! [locationAddress isEqualToString:incident.location.address ? incident.location.address : @""]) {
        NSLog(@"Location address edited.");

        if (! incident.location) {
            incident.location = [[Location alloc] initWithName:nil address:nil];
        }

        incident.location.address = locationAddress;
        self.locationDidChange = YES;
        self.window.documentEdited = YES;
    }
}


- (NSArray *) sourceForTableView:(NSTableView *)tableView
{
    if (tableView == self.rangersTable) {
        return self.incident.rangersByHandle.allValues;
    }
    else if (tableView == self.typesTable) {
        return self.incident.types;
    }
    else {
        performAlert(@"Table view unknown to IncidentController: %@", tableView);
        return nil;
    }
}


- (NSArray *) sortedSourceArrayForTableView:(NSTableView *)tableView
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@""
                                                                 ascending:YES];

    NSArray *source = [self sourceForTableView:tableView];

    return [source sortedArrayUsingDescriptors:@[descriptor]];
}


- (id) itemFromTableView:(NSTableView *)tableView row:(NSInteger)rowIndex
{
    if (rowIndex < 0) {
        return nil;
    }

    NSArray *sourceArray = [self sortedSourceArrayForTableView: tableView];

    if (rowIndex > (NSInteger)sourceArray.count) {
        NSLog(@"IncidentController got out of bounds rowIndex: %ld", rowIndex);
        return nil;
    }

    return sourceArray[(NSUInteger)rowIndex];
}



@end



@implementation IncidentController (NSWindowDelegate)


- (BOOL) windowShouldClose:(id)sender
{
    return YES;

    if (
        self.stateDidChange    ||
        self.priorityDidChange ||
        self.summaryDidChange  ||
        self.rangersDidChange  ||
        self.typesDidChange    ||
        self.locationDidChange
    ) {
        BOOL result;

        NSAlert *saveAlert = [NSAlert alertWithMessageText:@"Save incident?"
                                             defaultButton:@"Save"
                                           alternateButton:@"Cancel"
                                               otherButton:@"Don't Save"
                                 informativeTextWithFormat:@""];

        [saveAlert beginSheetModalForWindow:self.window
                              modalDelegate:self
                             didEndSelector:@selector(saveAlertDidEnd:returnCode:contextInfo:)
                                contextInfo:&result];

        NSLog(@"Should close: %d", result);
        return result;
    }

    NSLog(@"Should close.");
    return YES;
}


- (void) saveAlertDidEnd:(NSAlert *)alert
              returnCode:(int)returnCode
             contextInfo:(BOOL *)result
{
    NSLog(@"Return code: %d", returnCode);

    if (returnCode == 1) {
        [self save:self];
        *result = YES;
    }
    else if (returnCode == 0) {
        *result = NO;
    }
    else if (returnCode == -1) {
        *result = YES;
    }

    *result = NO;
}


- (void) windowWillClose:(NSNotification *)notification
{
    if (notification.object != self.window) {
        return;
    }

    //[self updateIncident];
}


@end



@implementation IncidentController (NSTableViewDataSource)


- (NSUInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.rangersTable) {
        return self.incident.rangersByHandle.count;
    }
    else if (tableView == self.typesTable) {
        return self.incident.types.count;
    }
    else {
        performAlert(@"Table view unknown to IncidentController: %@", tableView);
        return 0;
    }
}


- (id)            tableView:(NSTableView *)tableView
  objectValueForTableColumn:(NSTableColumn *)column
                        row:(NSInteger)rowIndex {
    return [self itemFromTableView:tableView row:rowIndex];
}


@end



@implementation IncidentController (NSTableViewDelegate)
@end



@implementation IncidentController (TableViewDelegate)


- (void) deleteFromTableView:(NSTableView *)tableView
{
    NSInteger rowIndex = tableView.selectedRow;

    id objectToDelete = [self itemFromTableView:tableView row:rowIndex];

    if (objectToDelete) {
        NSLog(@"Removing: %@", objectToDelete);

        if (tableView == self.rangersTable) {
            [self.incident removeRanger:objectToDelete];
            self.rangersDidChange = YES;
        }
        else if (tableView == self.typesTable) {
            [self.incident.types removeObject:objectToDelete];
            self.typesDidChange = YES;
        }
        else {
            performAlert(@"Table view unknown to IncidentController: %@", tableView);
            return;
        }
        self.window.documentEdited = YES;

        [self updateView];
    }
}


- (void) openFromTableView:(NSTableView *)tableView
{
}


@end



@implementation IncidentController (NSTextFieldDelegate)


- (NSArray *) completionSourceForControl:(NSControl *)control
{
    if (control == self.rangerToAddField) {
        return self.dispatchQueueController.dataStore.allRangersByHandle.allKeys;
    }

    if (control == self.typeToAddField) {
        return self.dispatchQueueController.dataStore.allIncidentTypes;
    }

    if (control == self.locationNameField) {
        return self.dispatchQueueController.dataStore.allLocationNames;
    }

    if (control == self.locationAddressField) {
        NSTextField *locationNameField = self.locationNameField;
        NSString *locationName = locationNameField.stringValue;
        return [self.dispatchQueueController.dataStore addressesForLocationName:locationName];
    }

    return nil;
}


- (NSArray *) completionsForWord:(NSString *)word
                      fromSource:(NSArray *)source
{
    if (! [word isEqualToString:@"?"]) {
        BOOL(^startsWithFilter)(NSString *, NSDictionary *) = ^(NSString *text, NSDictionary *bindings) {
            NSRange range = [text rangeOfString:word options:NSAnchoredSearch|NSCaseInsensitiveSearch];

            return (BOOL)(range.location != NSNotFound);
        };
        NSPredicate *predicate = [NSPredicate predicateWithBlock:startsWithFilter];

        source = [source filteredArrayUsingPredicate:predicate];
    }
    source = [source sortedArrayUsingSelector:NSSelectorFromString(@"localizedCaseInsensitiveCompare:")];

    return source;
}


- (NSArray *) control:(NSControl *)control
             textView:(NSTextView *)textView
          completions:(NSArray *)words
  forPartialWordRange:(NSRange)charRange
  indexOfSelectedItem:(NSInteger *)index
{
    NSArray *source = [self completionSourceForControl:control];

    if (! source) {
        performAlert(@"Completion request from unknown control: %@", control);
        return @[];
    }

    NSArray *completions = [self completionsForWord:textView.string fromSource:source];
    //NSLog(@"Completions: %@", completions);
    return completions;
}


- (void) controlTextDidChange:(NSNotification *)notification
{
    if (self.amBackspacing) {
        self.amBackspacing = NO;
        return;
    }

    if (! self.amCompleting) {
        self.amCompleting = YES;

        NSTextView *fieldEditor = [[notification userInfo] objectForKey:@"NSFieldEditor"];
        [fieldEditor complete:nil];

        self.amCompleting = NO;
    }
}


- (void)      control:(NSControl *)control
             textView:(NSTextView *)textView
  doCommandBySelector:(SEL)command
{
    if (control == self.rangerToAddField    ||
        control == self.typeToAddField      ||
        control == self.locationNameField   ||
        control == self.locationAddressField) {
        if (command == NSSelectorFromString(@"deleteBackward:")) {
            if (textView.string.length > 0) {
                self.amBackspacing = YES;
            }
        }
        else if (command == NSSelectorFromString(@"insertNewline:")) {
            if (control == self.rangerToAddField) {
                NSTextField *rangerToAddField = self.rangerToAddField;
                NSString *rangerHandle = rangerToAddField.stringValue;
                rangerHandle = [rangerHandle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

                if (rangerHandle.length > 0) {
                    Ranger *ranger = self.incident.rangersByHandle[rangerHandle];
                    if (! ranger) {
                        ranger = self.dispatchQueueController.dataStore.allRangersByHandle[rangerHandle];
                        if (ranger) {
                            NSLog(@"Ranger added: %@", ranger);
                            [self.incident addRanger:ranger];
                            self.rangersDidChange = YES;
                            self.window.documentEdited = YES;
                            rangerToAddField.stringValue = @"";
                            [self updateView];
                        }
                        else {
                            NSLog(@"Unknown Ranger: %@", rangerHandle);
                            NSBeep();
                        }
                    }
                }
            }
            else if (control == self.typeToAddField) {
                NSTextField *typeToAddField = self.typeToAddField;
                NSString *type = typeToAddField.stringValue;
                type = [type stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

                if (type.length > 0) {
                    if (! [self.incident.types containsObject:type]) {
                        if ([self.dispatchQueueController.dataStore.allIncidentTypes containsObject:type]) {
                            NSLog(@"Type added: %@", type);
                            [self.incident.types addObject:type];
                            self.typesDidChange = YES;
                            self.window.documentEdited = YES;
                            typeToAddField.stringValue = @"";
                            [self updateView];
                        }
                        else {
                            NSLog(@"Unknown incident type: %@", type);
                            NSBeep();
                        }
                    }
                }
            }
        }
        else {
            //NSLog(@"Do command: %@", NSStringFromSelector(command));
        }
    }
}


- (BOOL) textView:(NSTextView *)textView doCommandBySelector:(SEL)selector
{
    //NSLog(@"Do text command: %@", NSStringFromSelector(selector));
    if (textView == self.reportEntryToAddView) {
        if (selector == NSSelectorFromString(@"insertNewline:")) {
            NSTextView *reportEntryToAddView = self.reportEntryToAddView;
            [reportEntryToAddView insertNewlineIgnoringFieldEditor:self];
            return YES;
        }
    }
    return NO;
}


- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)range replacementString:(NSString *)replacement
{
    if (textView == self.reportEntriesView) {
        return NO;
    }
    return YES;
}


- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRanges:(NSArray *)ranges replacementStrings:(NSArray *)replacements
{
    if (textView == self.reportEntriesView) {
        return NO;
    }
    return YES;
}


@end
