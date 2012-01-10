//
//  OmronDataSyncOperation.m
//  pressure
//
//  Created by Sean Whitsell on 1/4/12.
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

#import "OmronDataSyncOperation.h"
#import "OmronDataSource.h"

@interface OmronDataSyncOperation()

@property (readwrite, nonatomic, retain) OmronDataSource* dataSource;

@end

@implementation OmronDataSyncOperation

@synthesize dataSource = mDataSource;

- (id)initWithDataSource:(OmronDataSource*)source 
{
    self = [super init];

    if (self != nil)
    {
        mDataSource = source; 
    }
    
    return self;
}

- (void)main 
{
    [mDataSource sync];
}

@end