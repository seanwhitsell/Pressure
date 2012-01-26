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
#import "ReadingViewController.h"
#import "OmronDataSource.h"

@interface MainWindowController ()

@property (nonatomic, readonly, retain) TabBarController *tabBarController;
@property (nonatomic, readwrite, retain) SyncButton *syncButton;
@property (nonatomic, readwrite, retain) OmronDataSource *dataSource;

- (void)toggleSync:(id)sender;
- (void)dataSyncOperationDidBegin:(NSNotification*)notif;
- (void)dataSyncOperationDidEnd:(NSNotification*)notif;
- (void)graphDataPointSelected:(NSNotification*)notif;

@end

@implementation MainWindowController

@synthesize syncButton = mSyncButton;
@synthesize box = mBox;
@synthesize dataSource = mDataSource;

- (id)init
{
	self = [super initWithWindowNibName:@"MainWindowController"];
	if (self != nil)
	{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataSyncOperationDidBegin:) name:OmronDataSyncDidBeginNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataSyncOperationDidEnd:) name:OmronDataSyncDidEndNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(graphDataPointSelected:) name:GraphDataPointWasSelectedNotification object:nil];
        
        mDataSource = [[OmronDataSource alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[mTabBarController release];
	mTabBarController = nil;
	
	[mSyncButton release];
	mSyncButton = nil;
	
	[mBox release];
	mBox = nil;
	
    [mDataSource release];
    mDataSource = nil;
    
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
	
	
	GraphViewController *vc1 = [[[GraphViewController alloc] initWithDatasource:self.dataSource] autorelease];
    
	vc1.tabBarItem.image = [NSImage imageNamed:@"Stock.icns"];
	vc1.tabBarItem.title = @"Graphs";
	vc1.tabBarItem.tag = 1;
	
	ReadingViewController *vc2 = [[[ReadingViewController alloc] initWithDatasource:self.dataSource] autorelease];
    
	vc2.tabBarItem.image = [NSImage imageNamed:@"List.icns"];
	vc2.tabBarItem.title = @"Readings";
	vc2.tabBarItem.tag = 2;

	self.tabBarController.viewControllers = [NSArray arrayWithObjects:vc1, vc2, nil];
	self.tabBarController.selectedViewController = vc1;
    
    [self.dataSource sync];
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

- (void)dataSyncOperationDidBegin:(NSNotification*)notif
{
    self.syncButton.syncing = YES;
}

- (void)dataSyncOperationDidEnd:(NSNotification*)notif
{
    self.syncButton.syncing = NO;
}

- (void)graphDataPointSelected:(NSNotification*)notif
{
    NSNumber* passedIndex = (NSNumber*)notif.object;
    NSUInteger index = [passedIndex integerValue];
    
    NSLog(@"Graph data point selected at %lu index", index);
    
   //
    // The user has clicked on a Data Point on the Graph. Let's switch to the Readings View and select
    // the Reading that this symbol came from
    // I dont like the magic number "1", but it IS the index from the array created above.
    //
    ReadingViewController *vc2 = [self.tabBarController.viewControllers objectAtIndex:1];
    vc2.listView.selectedRow = index;
    self.tabBarController.selectedViewController = vc2;

}

- (void)toggleSync:(id)sender
{
    if ([self.dataSource isSyncing])
    {
        [self.dataSource cancelSync];
    }
    else
    {
        [self.dataSource sync];
    }
}

@end
