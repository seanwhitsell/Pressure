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
//  TabBarController.m
//  Created by Ben Shanfelder on 1/4/12.
//

#import "TabBarController.h"
#import "TabBar.h"

@implementation TabBarController

@synthesize tabBar = mTabBar;
@synthesize containerView = mContainerView;
@synthesize splitterHandleImageView = mSplitterHandleImageView;

- (id)init
{
	self = [super initWithNibName:@"TabBarController" bundle:nil];
	if (self != nil)
	{
	}
	
	return self;
}

- (void)dealloc
{
	[mTabBar release];
	mTabBar = nil;
	
	[mContainerView release];
	mContainerView = nil;
	
	[mSplitterHandleImageView release];
	mSplitterHandleImageView = nil;
	
	[super dealloc];
}

#pragma mark - NSSplitViewDelegate

- (NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex
{
	return [splitView convertRect:[self.splitterHandleImageView bounds] fromView:self.splitterHandleImageView];
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view
{
	return (view != self.tabBar);
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	return 200.0f;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	return 80.0f;
}

@end
