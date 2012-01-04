//
//  omronDataSyncOperation.h
//  pressure
//
//  Created by Sean Whitsell on 1/4/12.
//

#import <Foundation/Foundation.h>


@class OmronDataSource;

@interface OmronDataSyncOperation : NSOperation {
    OmronDataSource* dataSource;
}

- (id)initWithDataSource:(OmronDataSource*)dataSource;

@end

