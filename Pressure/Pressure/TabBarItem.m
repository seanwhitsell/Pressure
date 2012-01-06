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
//  TabBarItem.m
//  Created by Ben Shanfelder on 1/4/12.
//

#import "TabBarItem.h"

@implementation TabBarItem

@synthesize image = mImage;
@synthesize title = mTitle;
@synthesize tag = mTag;
@synthesize badgeValue = mBadgeValue;

@synthesize target = mTarget;
@synthesize action = mAction;
@synthesize selected = mSelected;

@synthesize view = mView;

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		if ([NSBundle loadNibNamed:@"TabBarItem" owner:self])
		{
		}
	}
	
	return self;
}

- (void)dealloc
{
	[mImage release];
	mImage = nil;
	
	[mTitle release];
	mTitle = nil;
	
	[mBadgeValue release];
	mBadgeValue = nil;
	
	// not retained
	mTarget = nil;
	
	[mView release];
	mView = nil;
	
	[super dealloc];
}

#pragma mark - Private methods

- (IBAction)handleButton:(id)sender
{
	[self.target performSelector:self.action withObject:self];
}

@end
