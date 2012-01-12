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
	NSTextField *titleLabel;
}

@property (nonatomic, retain) IBOutlet NSTextField *titleLabel;

@end
