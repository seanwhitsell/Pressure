//
//  omronDataSource.h
//  pressure
//
//  Created by Sean Whitsell on 1/3/12.
//

#import <Foundation/Foundation.h>

extern NSString *OmronDataSyncDidBeginNotification;
extern NSString *OmronDataSyncDidEndNotification;

extern NSString *readingDateKey;
extern NSString *excludeReadingKey;
extern NSString *systolicPressureKey;
extern NSString *diastolicPressureKey;
extern NSString *heartRateKey;
extern NSString *dataBankKey;
extern NSString *deviceVersionKey;
extern NSString *deviceSerialNumberKey;

/*
 
 In order to retrieve the data from the device and the persistent store, instantiate an OmronDataSource
 and call 'sync'.
 
     OmronDataSource* myDataSource = [[OmronDataSource alloc] init];
     [myDataSource sync];
 
 When you receive the OmronDataSyncDidEndNotification notification, you can get an Array of NSManagedObjects;
 
 NSMutableArray* myReadings = [myDataSource readings];
 
 The NSManagedObjects have the following schema;
    NSDate -  readingDateKey
    int     - systolicPressureKey
    int     - diastolicPressureKey
    int     - heartRateKey
    int     - dataBankKey
    Bool    - excludeReadingKey
 
 Notes:
 The Omron BP791IT has 2 data banks (0,1)
 The Readings are unique by the Date
 The "exclude" flag is there to allow the user to mark readings to be excluded. This flag is saved in the 
 application persistent data when "sync" is called. The data on the Omron cannot be modified.
 
 Sample Use:
 
     for (NSManagedObject* reading in [myDataSource readings])
     {
        NSDate *readingDate = (NSDate*)[reading valueForKey:readingDateKey];
 
        // ... do something with the data here
     }
 
 */
@interface OmronDataSource : NSObject
{
    NSMutableArray *deviceList;
    NSMutableArray *readings;
    NSMutableArray *readingsListDates;
    NSString *deviceID;
}

//
// These will not be guaranteed until after OmronDataSyncDidEnd
//
@property (atomic, readonly, strong) NSString *deviceID;
@property (atomic, readwrite, strong) NSMutableArray *readings;

//
// Calling this will generate OmronDataSyncDidBegin and at some later point OmronDataSyncDidEnd
// 
// If there are readings that have had the "exclude" flag updated, that will be written to persistent store
//
- (void)sync;

@end