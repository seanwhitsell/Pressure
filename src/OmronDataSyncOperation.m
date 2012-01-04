//
//  OmronDataSyncOperation.m
//  pressure-test
//
//  Created by Sean Whitsell on 1/4/12.
//  Copyright (c) 2012 Cisco Systems, Inc. All rights reserved.
//

#import "OmronDataSyncOperation.h"
#import "OmronDataSource.h"

@interface OmronDataSyncOperation()

@property (readwrite, nonatomic, strong) OmronDataSource* dataSource;

@end

@implementation OmronDataSyncOperation

@synthesize dataSource = __dataSource;

- (id)initWithDataSource:(OmronDataSource*)source 
{
    self = [super init];

    if (self != nil)
    {
        __dataSource = source; 
    }
    
    return self;
}

- (void)main 
{
    [__dataSource sync];
}

@end