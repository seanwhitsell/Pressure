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
//  Created by Sean Whitsell on 3/9/12.
//

#import <AppKit/AppKit.h>

@protocol SWDatePickerProtocol;

@interface SWDatePicker : NSControl
{
@private
    NSDate *mRangeStartDate;
    NSDate *mRangeEndDate;
    NSDate *mDisplayedStartDate;
    NSDate *mDisplayedEndDate;
    NSDate *mSelectedStartDate;
    NSDate *mSelectedEndDate;
    id<SWDatePickerProtocol> mDelegate;
    
    NSImage *mMonthImage;
    NSImage *mMonthHightlightedImage;
    NSImage *mMonthSelectedImage;
    NSInteger mMaxMonths;
}

@property (nonatomic, readwrite, retain) NSDate *rangeStartDate;
@property (nonatomic, readwrite, retain) NSDate *rangeEndDate;
@property (nonatomic, readwrite, retain) NSDate *displayedStartDate;
@property (nonatomic, readwrite, retain) NSDate *displayedEndDate;
@property (nonatomic, readwrite, retain) NSDate *selectedStartDate;
@property (nonatomic, readwrite, retain) NSDate *selectedEndDate;
@property (nonatomic, readwrite, retain) NSImage *monthImage;
@property (nonatomic, readwrite, retain) NSImage *monthHightlightedImage;
@property (nonatomic, readwrite, retain) NSImage *monthSelectedImage;
@property (nonatomic, readwrite, assign) id<SWDatePickerProtocol> delegate;

@end

@protocol SWDatePickerProtocol <NSObject>

@optional
- (void)dateRangeSelectionChanged:(SWDatePicker*)control selectedStartDate:(NSDate*)start selectedEndDate:(NSDate*)end;

@end