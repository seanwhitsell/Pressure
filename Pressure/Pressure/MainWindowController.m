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
//  MainWindowController.m
//  Created by Ben Shanfelder on 1/4/12.
//

#import "MainWindowController.h"
#import "NSViewController+TabBarControllerItem.h"
#import "SyncButton.h"
#import "TabBarController.h"
#import "TabBarItem.h"
#import "TestViewController.h"
#import "GraphViewController.h"

@interface MainWindowController ()

@property (nonatomic, readonly, retain) TabBarController *tabBarController;
@property (nonatomic, readwrite, retain) SyncButton *syncButton;

- (void)toggleSync:(id)sender;

@end

@implementation MainWindowController

@synthesize syncButton = mSyncButton;
@synthesize box = mBox;

- (id)init
{
	self = [super initWithWindowNibName:@"MainWindowController"];
	if (self != nil)
	{
	}
	
	return self;
}

- (void)dealloc
{
	[mTabBarController release];
	mTabBarController = nil;
	
	[mSyncButton release];
	mSyncButton = nil;
	
	[mBox release];
	mBox = nil;
	
	[super dealloc];
}

- (void)windowDidLoad
{
	[self.box setContentView:[self.tabBarController view]];
	
	NSButton *windowCloseButton = [[self window] standardWindowButton:NSWindowCloseButton];
	NSRect frame = [windowCloseButton frame];
	frame.size.width = [SyncButton frameSize].width;
	frame.origin.x = NSMaxX([[windowCloseButton superview] frame]) - NSWidth(frame) - NSMinX(frame) + 4.0f;
	self.syncButton = [[[SyncButton alloc] initWithFrame:frame] autorelease];
	[self.syncButton setAction:@selector(toggleSync:)];
	[self.syncButton setTarget:self];
	[self.syncButton setAutoresizingMask:(NSViewMinXMargin | NSViewMinYMargin)];
	[[windowCloseButton superview] addSubview:self.syncButton];
	
	
	GraphViewController *vc1 = [[[GraphViewController alloc] init] autorelease];
	vc1.tabBarItem.image = [NSImage imageNamed:@"1325750140_Home"];
	vc1.tabBarItem.title = @"Graphs";
	vc1.tabBarItem.tag = 1;
	
	TestViewController *vc2 = [[[TestViewController alloc] init] autorelease];
	vc2.tabBarItem.image = [NSImage imageNamed:@"1325750134_Account and Control"];
	vc2.tabBarItem.title = @"Test 2";
	vc2.tabBarItem.tag = 2;
	
	TestViewController *vc3 = [[[TestViewController alloc] init] autorelease];
	vc3.tabBarItem.image = [NSImage imageNamed:@"1325750130_Control Panel"];
	vc3.tabBarItem.title = @"Test 3";
	vc3.tabBarItem.tag = 3;
	
	TestViewController *vc4 = [[[TestViewController alloc] init] autorelease];
	vc4.tabBarItem.image = [NSImage imageNamed:@"1325750145_Folder-Picture-2"];
	vc4.tabBarItem.title = @"Test 4";
	vc4.tabBarItem.tag = 4;
	
	self.tabBarController.viewControllers = [NSArray arrayWithObjects:vc1, vc2, vc3, vc4, nil];
	self.tabBarController.selectedViewController = vc2;
}

#pragma mark - Private methods

- (TabBarController *)tabBarController
{
	if (mTabBarController == nil)
	{
		mTabBarController = [[TabBarController alloc] init];
	}
	
	return mTabBarController;
}

- (void)toggleSync:(id)sender
{
	self.syncButton.syncing = !self.syncButton.isSyncing;
	// FIXME: Add the real code here to start and stop syncing.
	// This should probably be a roundtrip to the core.
	// For example, cancel should invoke the cancel command but only update the UI when cancel has been performed.
}

@end
