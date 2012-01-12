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
    
}

@property (nonatomic, retain) IBOutlet NSTextField *systolicPressureLabel;
@property (nonatomic, retain) IBOutlet NSTextField *diastolicPressureLabel;
@property (nonatomic, retain) IBOutlet NSTextField *readingDateLabel;


@end
