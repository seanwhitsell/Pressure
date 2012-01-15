//
//  OmronDataRecord.h
//  Pressure
//
//  Created by Sean Whitsell on 1/13/12.
//  Copyright (c) 2012 Cisco Systems, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OmronDataRecord : NSObject
{
    NSDate *mReadingDate;
    NSString *mSystolicPressure;
    NSString *mDiastolicPressure;
    NSString *mHeartRate;
    int mDataBank;
    BOOL mExcludeFromGraph;
}

@property (nonatomic, readwrite, retain) NSDate *readingDate;
@property (nonatomic, readwrite, retain) NSString *systolicPressure;
@property (nonatomic, readwrite, retain) NSString *diastolicPressure;
@property (nonatomic, readwrite, retain) NSString *heartRate;
@property (nonatomic, readwrite, assign) int dataBank;
@property (nonatomic, readwrite, assign) BOOL excludeFromGraph;

@end
