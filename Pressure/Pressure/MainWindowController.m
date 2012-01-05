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
//  MainWindowController.m
//  Created by Ben Shanfelder on 1/4/12.
//

#import "MainWindowController.h"
#import "TabBarController.h"

@interface MainWindowController ()

@property (nonatomic, readonly, retain) TabBarController *tabBarController;

@end

@implementation MainWindowController

@synthesize box = mBox;

- (id)init
{
	self = [super initWithWindowNibName:@"MainWindowController"];
	if (self != nil)
	{
	}
	
	return self;
}

- (void)dealloc
{
	[mBox release];
	mBox = nil;
	
	[super dealloc];
}

- (void)windowDidLoad
{
	[self.box setContentView:[self.tabBarController view]];
}

#pragma mark - Private methods

- (TabBarController *)tabBarController
{
	if (mTabBarController == nil)
	{
		mTabBarController = [[TabBarController alloc] init];
	}
	
	return mTabBarController;
}

@end
