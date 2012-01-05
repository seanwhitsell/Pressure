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
//  TabBarViewController.m
//  Created by Ben Shanfelder on 1/5/12.
//

#import "TabBarViewController.h"
#import "TabBarItem.h"

@implementation TabBarViewController

- (void)dealloc
{
	[mTabBarItem release];
	mTabBarItem = nil;
	
	[super dealloc];
}

- (TabBarItem *)tabBarItem
{
	if (mTabBarItem == nil)
	{
		mTabBarItem = [[TabBarItem alloc] init];
	}
	
	return mTabBarItem;
}

- (void)viewWillAppear
{
}

- (void)viewDidAppear
{
}

- (void)viewWillDisappear
{
}

- (void)viewDidDisappear
{
}

@end
