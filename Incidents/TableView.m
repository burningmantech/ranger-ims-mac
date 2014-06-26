////
// TableView.m
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

#import <objc/message.h>
#import "TableView.h"



@implementation TableView


- (void) keyDown:(NSEvent *)event
{
    id delegate = self.delegate;

    if (delegate && self.selectedRow != -1) {
        unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
        if (key == NSDeleteCharacter) {
            if ([delegate respondsToSelector:@selector(deleteFromTableView:)]) {
                [delegate deleteFromTableView:self];
                return;
            }
        }
        else if (
            key == NSCarriageReturnCharacter ||
            key == NSEnterCharacter          ||
            key == NSNewlineCharacter
        ) {
            if ([delegate respondsToSelector:@selector(openFromTableView:)]) {
                [delegate openFromTableView:self];
                return;
            }
        }
    }

    [super keyDown:event];
}

@end
