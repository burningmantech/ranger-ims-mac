////
// PreferencesController.m
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

#import "AppDelegate.h"
#import "PreferencesController.h"



@interface PreferencesController ()

@property (weak) AppDelegate *appDelegate;

@property (weak) IBOutlet NSTextField *serverNameField;
@property (weak) IBOutlet NSTextField *serverPortField;
@property (weak) IBOutlet NSButton    *serverUseTLSButton;

@end



@implementation PreferencesController


- (id) initWithAppDelegate:(AppDelegate *)appDelegate
{
    if (self = [super initWithWindowNibName:@"PreferencesController"]) {
        self.appDelegate = appDelegate;
    }
    return self;
}


- (void) windowDidLoad
{
    [super windowDidLoad];

    AppDelegate *appDelegate = self.appDelegate;

    NSTextField *serverNameField = self.serverNameField;
    serverNameField.stringValue = appDelegate.serverHostName;

    NSTextField *serverPortField = self.serverPortField;
    serverPortField.integerValue = appDelegate.serverPort.integerValue;

    NSButton *serverUseTLSButton = self.serverUseTLSButton;
    serverUseTLSButton.intValue = appDelegate.serverUseTLS ? 1 : 0;
}


- (IBAction) editServerName:(id)sender
{
    AppDelegate *appDelegate = self.appDelegate;
    NSTextField *field = sender;
    appDelegate.serverHostName = field.stringValue;
}


- (IBAction) editServerPort:(id)sender
{
    AppDelegate *appDelegate = self.appDelegate;
    NSTextField *field = sender;
    appDelegate.serverPort = [NSNumber numberWithInteger:field.integerValue];
}


- (IBAction) editServerUseTLS:(id)sender
{
    AppDelegate *appDelegate = self.appDelegate;
    NSButton *button = sender;
    appDelegate.serverUseTLS = (button.integerValue != 0);
}


@end
