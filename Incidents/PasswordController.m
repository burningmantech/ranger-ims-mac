////
// PasswordController.m
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
#import "PasswordController.h"



@interface PasswordController ()

@property (weak) AppDelegate *appDelegate;

@property (weak) IBOutlet NSTextField *userNameField;
@property (weak) IBOutlet NSTextField *passwordField;

@end



@implementation PasswordController


- (id) initWithAppDelegate:(AppDelegate *)appDelegate
{
    if (self = [super initWithWindowNibName:@"PasswordController"]) {
        self.appDelegate = appDelegate;
    }
    return self;
}


- (void) windowDidLoad
{
    [super windowDidLoad];

    self.window.backgroundColor = [NSColor colorWithSRGBRed:218.0f/256.0f
                                                      green:187.0f/256.0f
                                                       blue:154.0f/256.0f
                                                      alpha:1.0f];

    AppDelegate *appDelegate = self.appDelegate;

    NSTextField *userNameField = self.userNameField;
    userNameField.stringValue = appDelegate.serverUserName;

    NSTextField *passwordField = self.passwordField;
    passwordField.stringValue = @"";

    if (userNameField.stringValue.length > 0) {
        [self.window makeFirstResponder:passwordField];
    }
}


- (IBAction) editUserName:(id)sender
{
    [self dissmissIfReady];
}


- (IBAction) editPassword:(id)sender
{
    [self dissmissIfReady];
}


- (void) dissmissIfReady
{
    AppDelegate *appDelegate = self.appDelegate;

    NSTextField *userNameField = self.userNameField;
    NSString *userName = userNameField.stringValue;

    NSTextField *passwordField = self.passwordField;
    NSString *password = passwordField.stringValue;

    if (userName.length > 0 && password.length > 0) {
        appDelegate.serverUserName = userName;
        appDelegate.serverPassword = password;

        [self.window close];
        [NSApp stopModal];
    }
}


- (IBAction) quit:(id)sender
{
    [NSApp terminate:self];
}


@end
