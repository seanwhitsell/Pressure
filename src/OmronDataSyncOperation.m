//
//  OmronDataSyncOperation.m
//  pressure
//
//  Created by Sean Whitsell on 1/4/12.
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