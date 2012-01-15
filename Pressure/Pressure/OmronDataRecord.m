//
//  OmronDataRecord.m
//  Pressure
//
//  Created by Sean Whitsell on 1/13/12.
//  Copyright (c) 2012 Cisco Systems, Inc. All rights reserved.
//

#import "OmronDataRecord.h"

@implementation OmronDataRecord

@synthesize readingDate = mReadingDate;
@synthesize systolicPressure = mSystolicPressure;
@synthesize diastolicPressure = mDiastolicPressure;
@synthesize heartRate = mHeartRate;
@synthesize dataBank = mDataBank;
@synthesize excludeFromGraph = mExcludeFromGraph;

@end
