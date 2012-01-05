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
//  TabBar.m
//  Created by Ben Shanfelder on 1/4/12.
//

#import "TabBar.h"

@implementation TabBar

@synthesize delegate = mDelegate;
@synthesize items = mItems;
@synthesize selectedItem = mSelectedItem;

- (void)dealloc
{
	// not retained
	mDelegate = nil;
	
	[mItems release];
	mItems = nil;
	
	// not retained
	mSelectedItem = nil;
	
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSColor blackColor] set];
	NSRectFill(dirtyRect);
	
	[super drawRect:dirtyRect];
}

@end
