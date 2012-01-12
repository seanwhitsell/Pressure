//
//  ReadingViewController.m
//  Pressure
//
//  Created by Sean Whitsell on 1/12/12.
//  Copyright (c) 2012 Cisco Systems, Inc. All rights reserved.
//

#import "ReadingViewController.h"
#import "PXListView.h"
#import "PressureReadingViewCell.h"
#import "OmronDataSource.h"

#define LISTVIEW_CELL_IDENTIFIER		@"PressureReadingViewCell"

@interface ReadingViewController()

- (void)dataSyncOperationDidEnd:(NSNotification*)notif;

@end

@implementation ReadingViewController
@synthesize listView = mListView;
@synthesize dataSource = mDataSource;

- (id)init
{
	self = [super initWithNibName:@"ReadingViewController" bundle:nil];
	if (self != nil)
	{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataSyncOperationDidEnd:) name:OmronDataSyncDidEndNotification object:nil];
	}
	
	return self;
}

- (void)viewWillAppear
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
}

- (void)viewDidAppear
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
    [self.listView setCellSpacing:4.0f];
	[self.listView setAllowsEmptySelection:YES];
	[self.listView setAllowsMultipleSelection:YES];
	[self.listView registerForDraggedTypes:[NSArray arrayWithObjects: NSStringPboardType, nil]];
}

- (void)viewWillDisappear
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
}

- (void)viewDidDisappear
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
}    


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Notification Observers

- (void)dataSyncOperationDidEnd:(NSNotification*)notif
{
    // Table Reload
    NSLog(@"[ReadingViewController dataSyncOperationDidEnd] Data Source isSampleData %s", [mDataSource isSampleData] ? "yes":"no");
    [self.listView reloadData];
}

- (NSUInteger)numberOfRowsInListView:(PXListView*)aListView
{
    return 10; //[self.dataSource.readings count];
}

- (CGFloat)listView:(PXListView*)aListView heightOfRow:(NSUInteger)row
{
    return 60;
}

- (PXListViewCell*)listView:(PXListView*)aListView cellForRow:(NSUInteger)row
{
    NSLog(@"listView:cellForRow:%lu", row);
    PressureReadingViewCell *cell = (PressureReadingViewCell*)[aListView dequeueCellWithReusableIdentifier:LISTVIEW_CELL_IDENTIFIER];
	
	if(!cell) {
		cell = [PressureReadingViewCell cellLoadedFromNibNamed:@"PressureReadingViewCell" reusableIdentifier:LISTVIEW_CELL_IDENTIFIER];
	}
	
	// Set up the new cell:
	[[cell systolicPressureLabel] setStringValue:@"131"];
	
	return cell;
}

- (IBAction) reloadTable:(id)sender
{
	[self.listView reloadData];
}
@end
