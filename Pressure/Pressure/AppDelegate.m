//
// This file is part of Pressure.
//
// Pressure is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Pressure is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Pressure.  If not, see <http://www.gnu.org/licenses/>.
//
//  AppDelegate.m
//  Created by Ben Shanfelder on 1/4/12.
//

#import "AppDelegate.h"
#import "MainWindowController.h"

@interface AppDelegate ()

@property (nonatomic, readonly, retain) MainWindowController *mainWindowController;

@end

@implementation AppDelegate

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    //
    // Let's find out about the First-Launch
    //
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"firstLaunch",nil]];
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"usingSampleData",nil]];

	[self.mainWindowController showWindow:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application
{
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    //
    // First Launch is over
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"firstLaunch"];
}

#pragma mark - Private methods

- (MainWindowController *)mainWindowController
{
	if (mMainWindowController == nil)
	{
		mMainWindowController = [[MainWindowController alloc] init];
	}
	
	return mMainWindowController;
}

@end
