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
//  TabBarController.h
//  Created by Ben Shanfelder on 1/4/12.
//

#import <Cocoa/Cocoa.h>

@class TabBar;
@class TabBarItem;

@interface TabBarController : NSViewController <NSSplitViewDelegate>
{
	@private
	TabBar *mTabBar;
	NSView *mContainerView;
	NSImageView *mSplitterHandleImageView;
}

@end

@interface TabBarController ()

@property (nonatomic, readwrite, retain) IBOutlet TabBar *tabBar;
@property (nonatomic, readwrite, retain) IBOutlet NSView *containerView;
@property (nonatomic, readwrite, retain) IBOutlet NSImageView *splitterHandleImageView;

@end
