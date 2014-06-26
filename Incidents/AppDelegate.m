////
// AppDelegate.m
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
#import "FileDataStore.h"
#import "HTTPDataStore.h"
#import "DispatchQueueController.h"
#import "IncidentController.h"
#import "PreferencesController.h"
#import "PasswordController.h"
#import "AppDelegate.h"



@interface AppDelegate ()

@property (strong,nonatomic) DispatchQueueController *dispatchQueueController;
@property (strong,nonatomic) PreferencesController   *preferencesController;
@property (strong,nonatomic) PasswordController      *passwordController;

@property (weak) IBOutlet NSMenu *serverResourcesMenu;

@property (strong,nonatomic) NSString *dataStoreType;

@end



@implementation AppDelegate


- (id) init
{
    if (self = [super init]) {
    }
    return self;
}


- (void) connectionInfoChanged
{
    self.dispatchQueueController = nil;
}


- (NSString *) serverHostName
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString  *serverHostName = [defaults stringForKey:@"IMSServerHostName"];
    return serverHostName ? serverHostName : @"localhost";
}


- (void) setServerHostName:(NSString *)serverHostName
{
    if ([self.serverHostName isEqualToString:serverHostName]) { return; }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([serverHostName isEqualToString:@"localhost"]) {
        [defaults removeObjectForKey:@"IMSServerHostName"];
    }
    else {
        [defaults setObject:serverHostName forKey:@"IMSServerHostName"];
    }

    [self connectionInfoChanged];
}


- (NSNumber *) serverPort
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger serverPort = [defaults integerForKey:@"IMSServerPort"];
    return serverPort ? [NSNumber numberWithInteger:serverPort] : @8080;
}


- (void) setServerPort:(NSNumber *)serverPort
{
    if ([self.serverPort isEqualToNumber:serverPort]) { return; }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([serverPort isEqualToNumber:@8080]) {
        [defaults removeObjectForKey:@"IMSServerPort"];
    }
    else {
        [defaults setObject:serverPort forKey:@"IMSServerPort"];
    }

    [self connectionInfoChanged];
}


- (NSString *) serverUserName
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString  *serverUserName = [defaults stringForKey:@"IMSServerUserName"];
    return serverUserName ? serverUserName : @"";
}


- (void) setServerUserName:(NSString *)serverUserName
{
    if ([self.serverUserName isEqualToString:serverUserName]) { return; }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:serverUserName forKey:@"IMSServerUserName"];
}


- (DispatchQueueController *) dispatchQueueController
{
    if (! _dispatchQueueController) {
        id <DataStoreProtocol> dataStore;

        if ([self.dataStoreType isEqualToString:@"File"]) {
            dataStore = [[FileDataStore alloc] init];
        }
        else if ([self.dataStoreType isEqualToString:@"HTTP"]) {
            NSString *hostAndPort = [NSString stringWithFormat:@"%@:%@", self.serverHostName, self.serverPort];
            NSURL* url = [[NSURL alloc] initWithScheme:@"http" host:hostAndPort path:@"/"];
            dataStore = [[HTTPDataStore alloc] initWithURL:url];
        }
        else {
            performAlert(@"Unknown data store type: %@", self.dataStoreType);
            return nil;
        }

        NSLog(@"Initialized data store: %@", dataStore);

        _dispatchQueueController = [[DispatchQueueController alloc] initWithDataStore:dataStore appDelegate:self];
    }
    return _dispatchQueueController;
}
@synthesize dispatchQueueController=_dispatchQueueController;


- (void) setDispatchQueueController:(DispatchQueueController *)dispatchQueueController
{
    if (_dispatchQueueController) {
        // Better clean house
        for (IncidentController *incidentController in _dispatchQueueController.incidentControllers) {
            [incidentController.window close];
        }
        [_dispatchQueueController.window close];
    }

    _dispatchQueueController = dispatchQueueController;
}


- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.dataStoreType = @"HTTP";

    [self connectionInfoChanged];
    [self showDispatchQueue:self];
}


- (IBAction) showDispatchQueue:(id)sender
{
    [self.dispatchQueueController showWindow:self];
}


- (IBAction) newIncident:(id)sender
{
    [self.dispatchQueueController openNewIncident:self];
}


- (IBAction) findIncident:(id)sender
{
    [self.dispatchQueueController findIncident:self];
}


- (PreferencesController *) preferencesController
{
    if (! _preferencesController) {
        _preferencesController = [[PreferencesController alloc] initWithAppDelegate:self];
    }
    return _preferencesController;
}


- (IBAction) showPreferences:(id)sender
{
    [self.preferencesController showWindow:self];
}


- (PasswordController *) passwordController
{
    if (! _passwordController) {
        _passwordController = [[PasswordController alloc] initWithAppDelegate:self];
    }
    return _passwordController;
}


- (NSURLCredential *) credentialForChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (! challenge.proposedCredential || ! challenge.proposedCredential.hasPassword ||
        challenge.previousFailureCount > 0)
    {
        [self.passwordController showWindow:self];
        [self.passwordController.window makeKeyAndOrderFront:self];

        [NSApp runModalForWindow:self.passwordController.window];
    }

    return [NSURLCredential credentialWithUser:self.serverUserName
                                      password:self.serverPassword
                                   persistence:NSURLCredentialPersistenceForSession];
}


////
// Web Actions
////


- (void) openURLPathOnServer:(NSString *)path
{
    NSString *host = [NSString stringWithFormat:@"%@:%@", self.serverHostName, self.serverPort];
    NSURL *url = [[NSURL alloc] initWithScheme:@"http" host:host path:path];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (void) openLink:(NSMenuItem *)item
{
    NSDictionary *link = item.representedObject;
    NSLog(@"Opening link: %@", link);

    [self openURLPathOnServer:link[@"url"]];
}


- (void) updateLinks:(NSArray *)links
{
    NSMenu *serverResourcesMenu = self.serverResourcesMenu;

    [serverResourcesMenu removeAllItems];

    for (NSDictionary *link in links) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:link[@"name"]
                                                      action:NSSelectorFromString(@"openLink:")
                                               keyEquivalent:@""];
        item.target = self;
        item.representedObject = link;

        [serverResourcesMenu addItem:item];
    }
}


- (IBAction) openHelp:(id)sender
{
    [self openURLPathOnServer:@"/"];
}


//- (IBAction) logout:(id)sender
//{
//    self.serverPassword = nil;
//}


////
// Debug Menu Actions
////


- (IBAction) showOpenIncidents:(id)sender
{
    if (self.dispatchQueueController) {
        performAlert(@"%@", self.dispatchQueueController.incidentControllers);
    }
}


- (IBAction) showAllRangers:(id)sender
{
    if (self.dispatchQueueController) {
        performAlert(@"%@", self.dispatchQueueController.dataStore.allRangersByHandle);
    }
}


- (IBAction) showAllIncidentTypes:(id)sender
{
    if (self.dispatchQueueController) {
        performAlert(@"%@", self.dispatchQueueController.dataStore.allIncidentTypes);
    }
}


- (IBAction) showAllIncidents:(id)sender
{
    if (self.dispatchQueueController) {
        performAlert(@"%@", self.dispatchQueueController.dataStore.incidents);
    }
}


@end
