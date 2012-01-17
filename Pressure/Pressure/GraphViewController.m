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
//
//  GraphViewController.m
//  Created by Sean Whitsell on 1/8/12.
//

#import "GraphViewController.h"
#import "PXListView.h"
#import "PressureReadingViewCell.h"
#import "OmronDataSource.h"
#import "NSDate+Helper.h"
#import "OmronDataRecord.h"

#pragma mark Private Interface

@interface GraphViewController()

@property (nonatomic, readwrite, retain) NSArray *dataSourceSortedReadings;

- (void)dataSyncOperationDidEnd:(NSNotification*)notif;
- (void)dataSyncOperationDataAvailable:(NSNotification*)notif;

@end

@implementation GraphViewController

@synthesize dataSource = mDataSource;
@synthesize dataSourceSortedReadings = mDataSourceSortedReadings;
- (id)init
{
	self = [super initWithNibName:@"GraphViewController" bundle:nil];
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

#pragma mark NSNotification Observers

- (void)dataSyncOperationDidEnd:(NSNotification*)notif
{
    // Table Reload
    NSLog(@"[GraphViewController dataSyncOperationDidEnd] Data Source isSampleData %s", [mDataSource isSampleData] ? "yes":"no");
    
    self.dataSourceSortedReadings = [self.dataSource.readings sortedArrayUsingComparator:^(id a, id b) {
        NSDate *first = [(OmronDataRecord*)a readingDate];
        NSDate *second = [(OmronDataRecord*)b readingDate];
        return [first compare:second];
    }];
    
}

- (void)dataSyncOperationDataAvailable:(NSNotification*)notif
{
    // Table Reload
    NSLog(@"[GraphViewController dataSyncOperationDataAvailable] Data Source isSampleData %s", [mDataSource isSampleData] ? "yes":"no");
    
    self.dataSourceSortedReadings = [self.dataSource.readings sortedArrayUsingComparator:^(id a, id b) {
        NSDate *first = [(OmronDataRecord*)a readingDate];
        NSDate *second = [(OmronDataRecord*)b readingDate];
        return [first compare:second];
    }];

    
}


@end
