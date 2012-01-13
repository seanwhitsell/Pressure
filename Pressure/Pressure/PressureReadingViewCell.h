//
//  PressureReadingViewCell.h
//  Pressure
//
//  Created by Sean Whitsell on 1/11/12.
//  Copyright (c) 2012 Cisco Systems, Inc. All rights reserved.
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
}

@property (nonatomic, readwrite, retain) IBOutlet NSTextField *systolicPressureLabel;
@property (nonatomic, readwrite, retain) IBOutlet NSTextField *diastolicPressureLabel;
@property (nonatomic, readwrite, retain) IBOutlet NSTextField *readingDateLabel;
@property (nonatomic, readwrite, retain) IBOutlet NSTextField *heartRateLabel;
@property (nonatomic, readwrite, retain) IBOutlet NSButton *excludeCheckBox;

@end
