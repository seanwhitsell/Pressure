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
//  PressureReadingViewCell.h
//  Pressure
//
//  Created by Sean Whitsell on 1/11/12.
//

#import <Foundation/Foundation.h>

#import "PXListViewCell.h"

@interface PressureReadingViewCell : PXListViewCell
{
	NSTextField *mSystolicPressureLabel;
	NSTextField *mDiastolicPressureLabel;
	NSTextField *mReadingDateLabel;
    NSTextField *mHeartRateLabel;
    NSButton *mExcludeCheckBox;
    NSTextField *mDatabankName;
}

@property (nonatomic, readwrite, retain) IBOutlet NSTextField *systolicPressureLabel;
@property (nonatomic, readwrite, retain) IBOutlet NSTextField *diastolicPressureLabel;
@property (nonatomic, readwrite, retain) IBOutlet NSTextField *readingDateLabel;
@property (nonatomic, readwrite, retain) IBOutlet NSTextField *heartRateLabel;
@property (nonatomic, readwrite, retain) IBOutlet NSButton *excludeCheckBox;
@property (nonatomic, readwrite, retain) IBOutlet NSTextField *databankName;

@end
