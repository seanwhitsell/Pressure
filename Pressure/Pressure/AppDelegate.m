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
#import "PXUserDefaults.h"

@interface AppDelegate ()

@property (nonatomic, readonly, retain) MainWindowController *mainWindowController;

@end

@implementation AppDelegate

#pragma mark - NSApplicationDelegate

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		// Create the shared defaults and register our defaults early.
		[PXUserDefaults sharedDefaults];
	}
	
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	[self.mainWindowController showWindow:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application
{
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	[[PXUserDefaults sharedDefaults] setFirstLaunch:NO];
    [self.mainWindowController applicationWillTerminate:notification];
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
