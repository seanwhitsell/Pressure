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
//  PXUserDefaults.m
//  Created by Ben Shanfelder on 2/4/12.
//

#import "PXUserDefaults.h"

static NSString *const kFirstLaunchKey = @"firstLaunch";
static NSString *const kUsingSampleDataKey = @"usingSampleData";

@implementation PXUserDefaults

+ (PXUserDefaults *)sharedDefaults
{
	static PXUserDefaults *sInstance = nil;
	if (sInstance == nil)
	{
		sInstance = [[self alloc] init];
	}
	
	return sInstance;
}

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithBool:YES], kFirstLaunchKey,
								  [NSNumber numberWithBool:YES], kUsingSampleDataKey,
								  nil];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	}
	
	return self;
}

- (BOOL)firstLaunch
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:kFirstLaunchKey];
}

- (void)setFirstLaunch:(BOOL)firstLaunch
{
	[[NSUserDefaults standardUserDefaults] setBool:firstLaunch forKey:kFirstLaunchKey];
}

- (BOOL)usingSampleData
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:kUsingSampleDataKey];
}

- (void)setUsingSampleData:(BOOL)usingSampleData
{
	[[NSUserDefaults standardUserDefaults] setBool:usingSampleData forKey:kUsingSampleDataKey];
}

@end


@implementation NSApplication (PXUserDefaults)

- (PXUserDefaults *)sharedDefaults
{
	return [PXUserDefaults sharedDefaults];
}

@end
