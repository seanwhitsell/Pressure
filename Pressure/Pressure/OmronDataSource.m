//
//  omronDataSource.m
//  pressure
//
//  Created by Sean Whitsell on 1/3/12.
//
//  Copyright 2011 Sean Whitsell
//
//  This file is part of Pressure.
//
//  Pressure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Pressure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Pressure.  If not, see <http://www.gnu.org/licenses/>.
//

#import "OmronDataSource.h"
#import "OmronDataSyncOperation.h"
#import "OmronDataRecord.h"
#import "PXUserDefaults.h"

#include "omron.h"

NSString *OmronDataSyncDidBeginNotification = @"OmronDataSyncDidBeginNotification";
NSString *OmronDataSyncDataAvailableNotification = @"OmronDataSyncDataAvailableNotification";
NSString *OmronDataSyncDidEndNotification = @"OmronDataSyncDidEndNotification";
NSString *OmronDeviceConnectedNotification = @"OmronDeviceConnectedNotification";
NSString *OmronDeviceDisconnectedNotification = @"OmronDeviceDisconnectedNotification";
NSString *OmronDeviceNotPresentNotification = @"OmronDeviceNotPresentNotification";

NSString *readingDateKey = @"readingDateKey";
NSString *excludeReadingKey = @"excludeReadingKey";
NSString *systolicPressureKey = @"systolicPressureKey";
NSString *diastolicPressureKey = @"diastolicPressureKey";
NSString *heartRateKey = @"heartRateKey";
NSString *dataBankKey = @"dataBankKey";
NSString *deviceVersionKey = @"deviceVersionKey";
NSString *deviceSerialNumberKey = @"deviceSerialNumberKey";
NSString *commentKey = @"commentKey";

NSString *readingEntryEntityName = @"ReadingEntry";
NSString *deviceInformationEntityName = @"DeviceInformation";

//
// Private methods
//
@interface OmronDataSource()

@property (nonatomic, readwrite, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readwrite, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (atomic, readwrite, retain) NSString *deviceID;
@property (atomic, readwrite, retain) NSMutableArray *readingsListDates;
@property (atomic, readwrite, retain) NSMutableArray *deviceList;
@property (atomic, readwrite, assign) BOOL syncing;
@property (atomic, readwrite, assign) BOOL usingSampleData;

- (int)getOmronData;

@end

//
// Implementation
//
@implementation OmronDataSource

@synthesize persistentStoreCoordinator = myPersistentStoreCoordinator;
@synthesize managedObjectModel = myManagedObjectModel;
@synthesize managedObjectContext = myManagedObjectContext;
@synthesize deviceID = myDeviceID;
@synthesize readings = myReadings;
@synthesize readingsListDates = myReadingsListDates;
@synthesize deviceList = myDeviceList;
@synthesize syncing = mySyncing;
@synthesize usingSampleData = myUsingSampleData;

#pragma mark Object Lifecycle
- (id)init
{
	self = [super init];
    if (self != nil)
	{
        myReadingsListDates = [[NSMutableArray alloc] initWithCapacity:10];
        myUsingSampleData = NO; //[[PXUserDefaults sharedDefaults] usingSampleData];
    }
    
    return self;
}

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [myReadingsListDates release]; myReadingsListDates = nil;
    
    [super dealloc];
}

#pragma mark Public Operations

- (void)sync
{
    //
    // We will use this to post to the Main Thread
    //
    NSNotification *note;
    
    //
    // If we are on the MainThread, let's kick off our background operation
    //
    if ([NSThread isMainThread])
    {
        NSOperationQueue * queue = [[NSOperationQueue alloc] init];
        OmronDataSyncOperation *syncOperation = [[OmronDataSyncOperation alloc] initWithDataSource:self];
        [queue addOperation:syncOperation];
        return;
    }
    
    //
    // Post notification on main thread
    [self setSyncing:YES];
    note = [NSNotification notificationWithName:OmronDataSyncDidBeginNotification  object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:YES];

    //
    // Let's try to retrieve our latest device information from the persistent store
    //
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSError *error;
    NSEntityDescription *entity = [NSEntityDescription entityForName:deviceInformationEntityName inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors: [NSArray arrayWithObject:
                                       [[NSSortDescriptor alloc] initWithKey:deviceSerialNumberKey
                                                                   ascending:YES]]];
    
    //
    // Watch for a "cancel" before performing IO
    if (self.syncing)
    {
        self.deviceList = (NSMutableArray*)[context executeFetchRequest:fetchRequest error:&error];
    }
    
    NSLog(@"Device List is %@", self.deviceList);
    for (NSManagedObject *info in self.deviceList) {
        NSLog(@"deviceVersion: %@", [info valueForKey:deviceVersionKey]);
        NSLog(@"serialNumber: %@", [info valueForKey:deviceSerialNumberKey]);
    }        
    
    //
    // Now let's get the whole persistent data set of readings
    //
    entity = [NSEntityDescription entityForName:readingEntryEntityName inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors: [NSArray arrayWithObject:
                                       [[NSSortDescriptor alloc] initWithKey:readingDateKey
                                                                   ascending:YES]]];
    //
    // Watch for a "cancel"
    if (self.syncing)
    {
        //
        // This is the data that was persisted from the last run. 
        //
        NSMutableArray *realData = [[NSMutableArray alloc] initWithCapacity:100];
        
        //
        // Clear the previous list of Reading Dates
        [self.readingsListDates removeAllObjects];
        
        for (NSManagedObject *object in [context executeFetchRequest:fetchRequest error:&error])
        {
            OmronDataRecord *dataRecord = [[OmronDataRecord alloc] initWithManagedObject:object];            
            [realData addObject:dataRecord];
            
            //
            // This is an Array of the NSDates for all of the Existing Readings. We will use this
            // when we get all of the data from the device to see if the record is "new" or not
            [self.readingsListDates addObject:dataRecord.readingDate];
        }
        
        self.readings = realData;
    }       
    
    note = [NSNotification notificationWithName:OmronDataSyncDataAvailableNotification  object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:YES];
    
    //
    // Lastly, let's get the data off of the Device and fill in any new Readings
    //
    //
    // Watch for a "cancel"
    int retval = 0;
    if (self.syncing)
    {
        retval = [self getOmronData];
    }
    
    if (retval && ([self.readings count] == 0))
    {
    }
    else
    {
        //
        // Run the Fetch again, presuming that there was new data on the Device
        //
        NSMutableArray *realData = [[NSMutableArray alloc] initWithCapacity:100];
        
        for (NSManagedObject *object in [context executeFetchRequest:fetchRequest error:&error])
        {
            OmronDataRecord *dataRecord = [[OmronDataRecord alloc] initWithManagedObject:object];
            [realData addObject:dataRecord];
        }
        
        self.readings = realData;
        
    }
    //
    // Tell the application that we are done getting the Data
    //
    [self setSyncing:NO];
    note = [NSNotification notificationWithName:OmronDataSyncDidEndNotification  object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:YES];
}

- (void)cancelSync
{
    //
    // We will use this to post to the Main Thread
    //
    NSNotification *note;
    
    [self setSyncing:NO];
    note = [NSNotification notificationWithName:OmronDataSyncDidEndNotification  object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:YES];
}

- (void)saveUpdates
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error = nil;
    
    if (![context commitEditing]) {
        NSLog(@"%@: unable to commit editing before saving", [self class]);
    }
    
    if (![context save:&error])
    {
        NSLog(@"saveUpdates - Unresolved error %@, %@", error, [error userInfo]);
    }
}

#pragma mark Private Work

//
// getOmronData - This routine will read the data off of the Device
//
- (int)getOmronData 
{
    omron_device* device;
	int ret;
	int i;
	int data_count;
	unsigned char deviceVersion[64];
	unsigned char serialNumber[64];
    NSNotification *note;
    
	device = omron_create();
	
	ret = omron_get_count(device, OMRON_VID, OMRON_PID);
    
	if(!ret)
	{
		NSLog(@"No omron 790ITs connected!\n");
        note = [NSNotification notificationWithName:OmronDeviceNotPresentNotification object:nil userInfo:nil];
        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:YES];
		return 1;
	}
	NSLog(@"Found %d omron 790ITs\n", ret);
    
	ret = omron_open(device, OMRON_VID, OMRON_PID, 0);
	if(ret < 0)
	{
		NSLog(@"Cannot open omron 790IT!\n");
        note = [NSNotification notificationWithName:OmronDeviceNotPresentNotification object:nil userInfo:nil];
        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:YES];
		return 1;
	}
	NSLog(@"Opened omron 790IT\n %i", ret);
    
	ret = omron_get_device_version(device, deviceVersion);
	if(ret < 0)
	{
		NSLog(@"Cannot get device version!\n");
	}
	else
	{
		NSLog(@"Device version: %s\n", deviceVersion);
	}
    
    
	ret = omron_get_device_serial(device, serialNumber);
	if(ret < 0)
	{
		NSLog(@"Cannot get device prf!\n");
	}
	else
	{
		NSLog(@"Device serial: %s\n", serialNumber);
	}
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:deviceInformationEntityName inManagedObjectContext:self.managedObjectContext];
    
    for (NSString * deviceSerial in self.deviceList)
    {
        if ([deviceSerial isEqualToString:[NSString stringWithUTF8String:(char*)serialNumber]])
        {
            //skip
        }
        else
        {
            //add
            NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
            [newManagedObject setValue:[NSString stringWithUTF8String:(char*)serialNumber] forKey:deviceVersionKey];
            [newManagedObject setValue:[NSString stringWithUTF8String:(char*)deviceVersion] forKey:deviceSerialNumberKey];
        }
    }
    
    NSError *error = nil;
    if (![context save:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        //abort();
    }
    
    for (int bank = 0; bank < 2; bank++)
    {
        data_count = omron_get_daily_data_count(device, bank);
        NSLog(@"Found %d entries. Reading valuers now.", data_count);
        if(data_count < 0)
        {
            NSLog(@"Cannot get device prf!\n");
        }
        
        [[PXUserDefaults sharedDefaults] setUsingSampleData:NO];
        
        for(i = data_count - 1; i >= 0; --i)
        {
            if (self.syncing)
            {
                omron_bp_day_info r = omron_get_daily_bp_data(device, bank, i);
                if(!r.present)
                {
                    i = i + 1;
                    continue;
                }
                NSLog(@"%.2d/%.2d/20%.2d %.2d:%.2d:%.2d SYS: %3d DIA: %3d PULSE: %3d", r.day, r.month, r.year, r.hour, r.minute, r.second, r.sys,r.dia, r.pulse);
                
                NSDateComponents *comps = [[NSDateComponents alloc] init];
                [comps setDay:r.day];
                [comps setMonth:r.month];
                [comps setYear:2000 + r.year];
                [comps setHour:r.hour];
                [comps setMinute:r.minute];
                [comps setSecond:r.second];
                NSDate* readingDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
                
                unsigned index = (unsigned)CFArrayBSearchValues((__bridge CFArrayRef)self.readingsListDates,
                                                                CFRangeMake(0, CFArrayGetCount((__bridge CFArrayRef)self.readingsListDates)),
                                                                (__bridge CFDateRef)readingDate,
                                                                (CFComparatorFunction)CFDateCompare,
                                                                NULL);
                if (index < [self.readings count])
                {
                    // Already in the list
                    NSLog(@"Record already in list");
                }
                else
                {
                    NSLog(@"Adding record");
                    // need to add this one
                    NSEntityDescription *entity = [NSEntityDescription entityForName:readingEntryEntityName inManagedObjectContext: self.managedObjectContext];
                    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
                    [newManagedObject setValue:readingDate forKey:readingDateKey];
                    [newManagedObject setValue:[NSNumber numberWithBool:NO] forKey:excludeReadingKey];
                    [newManagedObject setValue:[NSNumber numberWithInt:r.sys] forKey:systolicPressureKey];
                    [newManagedObject setValue:[NSNumber numberWithInt:r.dia] forKey:diastolicPressureKey];
                    [newManagedObject setValue:[NSNumber numberWithInt:r.pulse] forKey:heartRateKey];
                    [newManagedObject setValue:[NSNumber numberWithInt:bank] forKey:dataBankKey];
                    [newManagedObject setValue:[NSString stringWithString:@""] forKey:commentKey];
                }
            }
        }
    }
    
    if (![context save:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        //abort();
    }
        
	ret = omron_close(device);
	if(ret < 0)
	{
		NSLog(@"Cannot close omron 790IT!\n");
		return 1;
	}
	return 0;
    
}

#pragma mark CoreData support

//
// applicationFilesDirectory - Returns the directory the application uses to store the Core Data store file. 
// This code uses a directory named "pressure" in the user's Library directory.
//
- (NSURL *)applicationFilesDirectory 
{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    return [libraryURL URLByAppendingPathComponent:@"Pressure"];
}

//
// managedObjectModel - Creates if necessary and returns the managed object model for the application.
//
- (NSManagedObjectModel *)managedObjectModel 
{
    if (myManagedObjectModel) {
        return myManagedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Pressure" withExtension:@"momd"];
    myManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return myManagedObjectModel;
}

/**
 Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator 
{
    if (myPersistentStoreCoordinator) 
    {
        return myPersistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) 
    {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];
    
    if (!properties) 
    {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) 
        {
            //
            // This is a first-run scenario. There is no persistent store file. We will create one
            //
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) 
        {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    else 
    {
        if ([[properties objectForKey:NSURLIsDirectoryKey] boolValue] != YES) 
        {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]]; 
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"PRESSURE_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"Pressure.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) 
    {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    myPersistentStoreCoordinator = coordinator;
    
    return myPersistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *)managedObjectContext 
{
    if (myManagedObjectContext) {
        return myManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    myManagedObjectContext = [[NSManagedObjectContext alloc] init];
    [myManagedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return myManagedObjectContext;
}

@end
