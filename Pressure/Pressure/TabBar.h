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
//  TabBar.h
//  Created by Ben Shanfelder on 1/4/12.
//

#import <Cocoa/Cocoa.h>

@class TabBarItem;
@protocol TabBarDelegate;

@interface TabBar : NSView
{
	@private
	id<TabBarDelegate> mDelegate;
	NSArray *mItems;
	TabBarItem *mSelectedItem;
}

@property (nonatomic, readwrite, assign) id<TabBarDelegate> delegate;
@property (nonatomic, readwrite, copy) NSArray *items;
@property (nonatomic, readwrite, assign) TabBarItem *selectedItem;

@end

@protocol TabBarDelegate <NSObject>

- (void)tabBar:(TabBar *)tabBar didSelectItem:(TabBarItem *)item;

@end
