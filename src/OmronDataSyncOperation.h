//
//  omronDataSyncOperation.h
//  pressure-test
//
//  Created by Sean Whitsell on 1/4/12.
//  Copyright (c) 2012 Cisco Systems, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@class OmronDataSource;

@interface OmronDataSyncOperation : NSOperation {
    OmronDataSource* dataSource;
}

- (id)initWithDataSource:(OmronDataSource*)dataSource;

@end

