//
// This file is part of Pressure.
//
// Pressure is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Pressure is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Pressure.  If not, see <http://www.gnu.org/licenses/>.
//
//  OmronDataRecord.m
//  Pressure
//
//  Created by Sean Whitsell on 1/11/12.
//

#import "OmronDataRecord.h"

@interface OmronDataRecord()

@property (nonatomic, readwrite, retain) NSManagedObject *object;

@end

@implementation OmronDataRecord

@synthesize readingDate = mReadingDate;
@synthesize systolicPressure = mSystolicPressure;
@synthesize diastolicPressure = mDiastolicPressure;
@synthesize heartRate = mHeartRate;
@synthesize dataBank = mDataBank;
@synthesize excludeFromGraph = mExcludeFromGraph;
@synthesize comment = mComment;
@synthesize object = mObject;

- (id)initWithManagedObject:(NSManagedObject*)object
{
    self = [super init];
    if (self) 
    {
        mObject = object;
    }
    
    return self;

}

- (NSDate *)readingDate
{
    return (NSDate *)[self.object valueForKey:readingDateKey];
}

- (NSInteger)systolicPressure
{
    return [(NSNumber*)[self.object valueForKey:systolicPressureKey] longValue];
}

- (NSInteger)diastolicPressure
{
    return [(NSNumber*)[self.object valueForKey:diastolicPressureKey] longValue];
}

- (NSInteger)heartRate
{
    return [(NSNumber*)[self.object valueForKey:heartRateKey] longValue];
}

- (NSInteger)dataBank
{
    return [(NSNumber*)[self.object valueForKey:dataBankKey] longValue];
}

- (BOOL)excludeFromGraph
{
    return [(NSNumber*)[self.object valueForKey:excludeReadingKey] boolValue];
}

- (NSString *)comment
{
    return [NSString stringWithFormat:@"%@", [self.object valueForKey:commentKey]];
}

- (void)setReadingDate:(NSDate *)readingDate
{
    [self.object setValue:readingDate forKey:readingDateKey];
}

- (void)setSystolicPressure:(NSInteger)systolicPressure
{
    [self.object setValue:[NSNumber numberWithInteger:systolicPressure] forKey:systolicPressureKey];
}
 
- (void)setDiastolicPressure:(NSInteger)diastolicPressure
{
    [self.object setValue:[NSNumber numberWithInteger:diastolicPressure] forKey:diastolicPressureKey];    
}

- (void)setHeartRate:(NSInteger)heartRate
{
    [self.object setValue:[NSNumber numberWithInteger:heartRate] forKey:heartRateKey];
   
}

- (void)setDataBank:(NSInteger)dataBank
{
    [self.object setValue:[NSNumber numberWithInteger:dataBank] forKey:dataBankKey];   
}

- (void)setExcludeFromGraph:(BOOL)excludeFromGraph
{
    [self.object setValue:[NSNumber numberWithBool:excludeFromGraph] forKey:excludeReadingKey];
  
}

- (void)setComment:(NSString *)comment
{
    [self.object setValue:[NSString stringWithString:comment] forKey:commentKey];
}

@end
