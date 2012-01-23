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
//  ReadingViewController.h
//  Pressure
//
//  Created by Sean Whitsell on 1/11/12.

#import <Cocoa/Cocoa.h>
#import "PXListView.h"

@class PXListView;
@class OmronDataSource;

@interface ReadingViewController : NSViewController <PXListViewDelegate>
{
    OmronDataSource *mDataSource;
    PXListView *mListView;
    NSArray *mDataSourceSortedReadings;
}

@property (nonatomic, readonly, retain) OmronDataSource *dataSource;
@property (nonatomic, readwrite, assign) IBOutlet PXListView *listView;

- (id)initWithDatasource:(OmronDataSource*)aDataSource;

@end
