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

@property (nonatomic, readwrite, retain) OmronDataSource *dataSource;
@property (nonatomic, readwrite, retain) NSArray *dataSourceSortedReadings;
@property (nonatomic, readwrite, assign) NSInteger selectedRow;
@property (nonatomic, readwrite, assign) UserFilter userFilter;

- (void)dataSyncOperationDidEnd:(NSNotification*)notif;
- (void)dataSyncOperationDataAvailable:(NSNotification*)notif;
- (void)userFilterDidChange:(NSNotification*)notif;

@end

#pragma mark Implementation

@implementation ReadingViewController

@synthesize listView = mListView;
@synthesize dataSource = mDataSource;
@synthesize dataSourceSortedReadings = mReadings;
@synthesize selectedRow = mSelectedRow;
@synthesize userFilter = mUserFilter;

#pragma mark -
#pragma mark NSObject Lifecycle Routines

- (id)initWithDatasource:(OmronDataSource*)aDataSource
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);

    [self init];
    mDataSource = aDataSource;
    mSelectedRow = -1;
    
    return self;
}

- (id)init
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);

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
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(userFilterDidChange:) 
                                                     name:UserFilterDidChangeNotification 
                                                   object:nil];
        

	}
	
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Utility Routines

- (void)selectAndPositionRecord:(OmronDataRecord*)aRecord
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);

    for (unsigned int row = 0; row < [self.dataSourceSortedReadings count]; row++) 
    {
        OmronDataRecord *record = [self.dataSourceSortedReadings objectAtIndex:row];
        
        if (aRecord == record)
        {
            if ([self listView])
            {
                [self.listView scrollToRow:row-4];
                [self.listView setSelectedRow:row];
            }
            else
            {
                //
                // This is the first time that the ReadingViewController is being drawn
                // and we have not awaken from the NIB.
                //
                // We will store the selected row and then set it in the AwakeFromNib routine
                self.selectedRow = row;
            }
        }
    }
}

#pragma mark -
#pragma mark NSViewController overrides

- (void)awakeFromNib
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
    [self.listView setCellSpacing:1.0f];
    [self.listView setAllowsEmptySelection:YES];
    [self.listView setAllowsMultipleSelection:YES];
    [self.listView registerForDraggedTypes:[NSArray arrayWithObjects: NSStringPboardType, nil]];
    [self.listView reloadData];
    
    if (self.selectedRow > 0)
    {
        [self.listView scrollRowToVisible:self.selectedRow-4];
        [self.listView setSelectedRow:self.selectedRow];
    }

}

- (void)viewWillAppear
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
}

- (void)viewDidAppear
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
    NSUInteger index = self.listView.selectedRow;
    [self.listView scrollRowToVisible:index];
}

- (void)viewWillDisappear
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
}

- (void)viewDidDisappear
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
}    

#pragma mark -
#pragma mark NSNotification Observers

- (void)dataSyncOperationDidEnd:(NSNotification*)notif
{
    // Table Reload    
    self.dataSourceSortedReadings = [self.dataSource.omronDataRecords sortedArrayUsingComparator:^(id a, id b) {
        NSDate *first = [(OmronDataRecord*)a readingDate];
        NSDate *second = [(OmronDataRecord*)b readingDate];
        return [second compare:first];
    }];
    
    NSPredicate *userPredicate = nil;
    if ((self.userFilter == userAOnly) || (self.userFilter == userBOnly))
    {
        //
        // Take a shortcut with self.userFilter by casting it as an (int) to get 0 for UserA and 1 for UserB
        //
        userPredicate = [NSPredicate predicateWithFormat:@"dataBank == %i", (int)self.userFilter];
        self.dataSourceSortedReadings = [self.dataSourceSortedReadings filteredArrayUsingPredicate:userPredicate];
    }
    else
    {
        // Otherwise, we do not filter by the User
    }

    [self.listView reloadData];
}

- (void)dataSyncOperationDataAvailable:(NSNotification*)notif
{
    // Table Reload
    self.dataSourceSortedReadings = [self.dataSource.omronDataRecords sortedArrayUsingComparator:^(id a, id b) {
        NSDate *first = [(OmronDataRecord*)a readingDate];
        NSDate *second = [(OmronDataRecord*)b readingDate];
        return [second compare:first];
    }];

    NSPredicate *userPredicate = nil;
    if ((self.userFilter == userAOnly) || (self.userFilter == userBOnly))
    {
        //
        // Take a shortcut with self.userFilter by casting it as an (int) to get 0 for UserA and 1 for UserB
        //
        userPredicate = [NSPredicate predicateWithFormat:@"dataBank == %i", (int)self.userFilter];
        self.dataSourceSortedReadings = [self.dataSourceSortedReadings filteredArrayUsingPredicate:userPredicate];
    }
    else
    {
        // Otherwise, we do not filter by the User
    }

    [self.listView reloadData];
}

- (void)excludeCheckBoxDidChange:(PressureReadingViewCell*)cell toValue:(BOOL)newValue
{
    OmronDataRecord *record = (OmronDataRecord *)[[cell excludeCheckBox] tag];
    
    record.excludeFromGraph = newValue;
}

- (void)commentDidChange:(PressureReadingViewCell*)cell toValue:(NSString*)newValue
{
    OmronDataRecord *record = (OmronDataRecord *)[[cell commentLabel] tag];
    
    record.comment = newValue;    
}

- (void)userFilterDidChange:(NSNotification*)notif
{
    //
    // Receive the new filter value
    self.userFilter = (UserFilter)[[notif object] intValue];
    NSLog(@"Changing the userFilter to %i", self.userFilter);
    
    //
    // Reset the array to the original, unsorted, unfiltered dataset
    //
    self.dataSourceSortedReadings = self.dataSource.omronDataRecords;
    
    NSPredicate *userPredicate = nil;
    if ((self.userFilter == userAOnly) || (self.userFilter == userBOnly))
    {
        //
        // Take a shortcut with self.userFilter by casting it as an (int) to get 0 for UserA and 1 for UserB
        //
        userPredicate = [NSPredicate predicateWithFormat:@"dataBank == %i", (int)self.userFilter];
        self.dataSourceSortedReadings = [self.dataSourceSortedReadings filteredArrayUsingPredicate:userPredicate];
    }
    else
    {
        // Otherwise, we do not filter by the User
    }

    [self.listView reloadData];
}

#pragma mark -
#pragma mark PXListViewDelegate delelate implementation

- (NSUInteger)numberOfRowsInListView:(PXListView*)aListView
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
    return [self.dataSourceSortedReadings count];
}

- (CGFloat)listView:(PXListView*)aListView heightOfRow:(NSUInteger)row
{
    return 60;
}

- (PXListViewCell*)listView:(PXListView*)aListView cellForRow:(NSUInteger)row
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
    
    OmronDataRecord *record = [self.dataSourceSortedReadings objectAtIndex:row];
    PressureReadingViewCell *cell = (PressureReadingViewCell*)[aListView dequeueCellWithReusableIdentifier:LISTVIEW_CELL_IDENTIFIER];
	
	if(!cell) {
		cell = [PressureReadingViewCell cellLoadedFromNibNamed:@"PressureReadingViewCell" reusableIdentifier:LISTVIEW_CELL_IDENTIFIER];  
	}
	
    //
	// Set up the new cell:
	[[cell systolicPressureLabel] setStringValue:[NSString stringWithFormat:@"%i",record.systolicPressure]];
	[[cell diastolicPressureLabel] setStringValue:[NSString stringWithFormat:@"%i",record.diastolicPressure]];
    [[cell heartRateLabel] setStringValue:[NSString stringWithFormat:@"%i",record.heartRate]];
    NSString *displayString = [NSDate stringForDisplayFromDate:record.readingDate
                               prefixed:NO
                               alwaysDisplayTime:YES];
    [[cell readingDateLabel] setStringValue:displayString];
    
    //
    // we want to be able to reference the Record to update when we get the Notification that A
    // NSTextField "controlTextDidendEditing". This gives us a handy reference
    [cell setDelegate:self];
    [[cell commentLabel] setStringValue:record.comment];
    [[cell commentLabel] setTag:(NSInteger)record];
    
    [[cell excludeCheckBox] setState:record.excludeFromGraph];
    [[cell excludeCheckBox] setTag:(NSInteger)record];
    
    if ([record dataBank] == 0)
    {
        [[cell databankName] setStringValue:@"User A"];
    }
    else
    {
        [[cell databankName] setStringValue:@"User B"];
    }
    
	NSLog(@"<%p> %@", self, cell.commentLabel);
          
	return cell;
}

@end
