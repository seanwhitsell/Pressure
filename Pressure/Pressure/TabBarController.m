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
#import "NSViewController+TabBarControllerItem.h"
#import "TabBar.h"
#import "TabBarItem.h"
#import "TabBarItemView.h"

@interface TabBarController ()

- (void)tabBarItemClicked:(id)sender;

@end

@implementation TabBarController

@synthesize delegate = mDelegate;
@synthesize viewControllers = mViewControllers;
@synthesize selectedViewController = mSelectedViewController;

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
	// not retained
	mDelegate = nil;
	
	[mViewControllers release];
	mViewControllers = nil;
	
	// not retained
	mSelectedViewController = nil;
	
	[mTabBar release];
	mTabBar = nil;
	
	[mContainerView release];
	mContainerView = nil;
	
	[mSplitterHandleImageView release];
	mSplitterHandleImageView = nil;
	
	[super dealloc];
}

- (void)setViewControllers:(NSArray *)viewControllers
{
	if (![viewControllers isEqualToArray:mViewControllers])
	{
		NSUInteger oldSelectedIndex = (mViewControllers != nil) ? [mViewControllers indexOfObject:self.selectedViewController] : NSNotFound;
		
		[mViewControllers release];
		mViewControllers = [viewControllers copy];
		
		NSArray *items = [viewControllers valueForKey:@"tabBarItem"];
		for (TabBarItem *item in items)
		{
			item.target = self;
			item.action = @selector(tabBarItemClicked:);
		}
		
		self.tabBar.items = items;
		
		if (oldSelectedIndex != NSNotFound)
		{
			if (![viewControllers containsObject:self.selectedViewController])
			{
				NSViewController *viewController = nil;
				if (oldSelectedIndex < [viewControllers count])
				{
					viewController = [viewControllers objectAtIndex:oldSelectedIndex];
				}
				else if ([viewControllers count] > 0)
				{
					viewController = [viewControllers objectAtIndex:0];
				}
				
				self.selectedViewController = viewController;
			}
			else
			{
				self.tabBar.selectedItem = self.selectedViewController.tabBarItem;
			}
		}
	}
}

- (void)setSelectedViewController:(NSViewController *)selectedViewController
{
	if ((selectedViewController != mSelectedViewController) && [self.viewControllers containsObject:selectedViewController])
	{
		NSViewController *oldSelectedViewController = mSelectedViewController;
		mSelectedViewController = selectedViewController;
		
		[oldSelectedViewController viewWillDisappear];
		[selectedViewController viewWillAppear];
		
		[[oldSelectedViewController view] removeFromSuperview];
		[self.containerView addSubview:[selectedViewController view]];
		[[selectedViewController view] setFrame:[self.containerView bounds]];
		
		if (selectedViewController != nil)
		{
			// Add the view controller to the responder chain.
			NSResponder *responder = [[selectedViewController view] nextResponder];
			[selectedViewController setNextResponder:responder];
			[[selectedViewController view] setNextResponder:selectedViewController];
		}
		
		self.tabBar.selectedItem = selectedViewController.tabBarItem;
		
		[oldSelectedViewController viewDidDisappear];
		[selectedViewController viewDidAppear];
		
		// Try to select the inner content.
		NSWindow *window = [[self view] window];
		[window recalculateKeyViewLoop];
		NSView *nextValidKeyView = [[selectedViewController view] nextValidKeyView];
		if (nextValidKeyView != nil)
		{
			[window makeFirstResponder:nextValidKeyView];
		}
		
		[self.delegate tabBarController:self didSelectViewController:selectedViewController];
	}
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
	return 128.0f;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	return 64.0f;
}

#pragma mark - Private methods

- (void)tabBarItemClicked:(id)sender
{
	for (NSViewController *viewController in self.viewControllers)
	{
		if (viewController.tabBarItem == sender)
		{
			self.selectedViewController = viewController;
			break;
		}
	}
}

@end
