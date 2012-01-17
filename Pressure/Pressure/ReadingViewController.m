//
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
//  ReadingViewController.m
//  Pressure
//
//  Created by Sean Whitsell on 1/11/12.

#import "ReadingViewController.h"
#import "PXListView.h"
#import "PressureReadingViewCell.h"
#import "OmronDataSource.h"
#import "NSDate+Helper.h"
#import "OmronDataRecord.h"

#define LISTVIEW_CELL_IDENTIFIER @"PressureReadingViewCell"

#pragma mark Private Interface

@interface ReadingViewController()

@property (nonatomic, readwrite, retain) NSArray *dataSourceSortedReadings;

- (void)dataSyncOperationDidEnd:(NSNotification*)notif;
- (void)dataSyncOperationDataAvailable:(NSNotification*)notif;

@end

#pragma mark Implementation

@implementation ReadingViewController

@synthesize listView = mListView;
@synthesize dataSource = mDataSource;
@synthesize dataSourceSortedReadings = mDataSourceSortedReadings;

#pragma mark NSObject Lifecycle Routines

- (id)init
{
	self = [super initWithNibName:@"ReadingViewController" bundle:nil];
	if (self != nil)
	{
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(dataSyncOperationDidEnd:) 
                                                     name:OmronDataSyncDidEndNotification 
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(dataSyncOperationDataAvailable:) 
                                                     name:OmronDataSyncDataAvailableNotification 
                                                   object:nil];
	}
	
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark NSViewController overrides

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

#pragma mark NSNotification Observers

- (void)dataSyncOperationDidEnd:(NSNotification*)notif
{
    // Table Reload
    NSLog(@"[ReadingViewController dataSyncOperationDidEnd] Data Source isSampleData %s", [mDataSource isSampleData] ? "yes":"no");
    
    self.dataSourceSortedReadings = [self.dataSource.readings sortedArrayUsingComparator:^(id a, id b) {
        NSDate *first = [(OmronDataRecord*)a readingDate];
        NSDate *second = [(OmronDataRecord*)b readingDate];
        return [first compare:second];
    }];
    
    [self.listView reloadData];
}

- (void)dataSyncOperationDataAvailable:(NSNotification*)notif
{
    // Table Reload
    NSLog(@"[ReadingViewController dataSyncOperationDataAvailable] Data Source isSampleData %s", [mDataSource isSampleData] ? "yes":"no");

    self.dataSourceSortedReadings = [self.dataSource.readings sortedArrayUsingComparator:^(id a, id b) {
        NSDate *first = [(OmronDataRecord*)a readingDate];
        NSDate *second = [(OmronDataRecord*)b readingDate];
        return [first compare:second];
    }];

    [self.listView reloadData];
}

#pragma mark PXListViewDelegate delelate implementation

- (NSUInteger)numberOfRowsInListView:(PXListView*)aListView
{
    return [self.dataSourceSortedReadings count];
}

- (CGFloat)listView:(PXListView*)aListView heightOfRow:(NSUInteger)row
{
    return 60;
}

- (PXListViewCell*)listView:(PXListView*)aListView cellForRow:(NSUInteger)row
{
    NSLog(@"listView:cellForRow:%lu", row);
    
    OmronDataRecord *record = [self.dataSourceSortedReadings objectAtIndex:row];
    PressureReadingViewCell *cell = (PressureReadingViewCell*)[aListView dequeueCellWithReusableIdentifier:LISTVIEW_CELL_IDENTIFIER];
	
	if(!cell) {
		cell = [PressureReadingViewCell cellLoadedFromNibNamed:@"PressureReadingViewCell" reusableIdentifier:LISTVIEW_CELL_IDENTIFIER];
	}
	
	// Set up the new cell:
	[[cell systolicPressureLabel] setStringValue:record.systolicPressure];
	[[cell diastolicPressureLabel] setStringValue:record.diastolicPressure];
    [[cell heartRateLabel] setStringValue:record.heartRate];
    NSString *displayString = [NSDate stringForDisplayFromDate:record.readingDate
                               prefixed:NO
                               alwaysDisplayTime:YES];
    [[cell readingDateLabel] setStringValue:displayString];
	return cell;
}

@end
