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
#import "TabBarItem.h"
#import "TabBarItemView.h"

@interface TabBar ()

- (void)layoutSubviews;
- (void)handleOverflowMenuItem:(id)sender;

@end

@implementation TabBar

@synthesize items = mItems;
@synthesize selectedItem = mSelectedItem;

@synthesize containerView = mContainerView;
@synthesize overflowPopUpButton = mOverflowPopUpButton;

- (void)dealloc
{
	[mItems release];
	mItems = nil;
	
	// not retained
	mSelectedItem = nil;
	
	[mContainerView release];
	mContainerView = nil;
	
	[mOverflowPopUpButton release];
	mOverflowPopUpButton = nil;
	
	[super dealloc];
}

- (void)setFrame:(NSRect)frameRect
{
	[super setFrame:frameRect];
	[self layoutSubviews];
}

- (void)drawRect:(NSRect)dirtyRect
{
//	NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor blackColor] endingColor:[NSColor colorWithDeviceWhite:0.2f alpha:1.0f]] autorelease];
//	[gradient drawInRect:[self frame] angle:10.0f];
	
	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];
	[context setPatternPhase:NSMakePoint(0.0f, NSHeight([self bounds]))];
	
	[[NSColor colorWithPatternImage:[NSImage imageNamed:@"backgroundDark"]] set];
	NSRectFill([self bounds]);
	
	[context restoreGraphicsState];
	
	[super drawRect:dirtyRect];
}

- (void)setItems:(NSArray *)items
{
	if (![items isEqualToArray:mItems])
	{
		[[mItems valueForKey:@"view"] makeObjectsPerformSelector:@selector(removeFromSuperview)];
		
		[mItems release];
		mItems = [items copy];
		
		[self layoutSubviews];
	}
}

- (void)setSelectedItem:(TabBarItem *)selectedItem
{
	if ((selectedItem != mSelectedItem) && [self.items containsObject:selectedItem])
	{
		mSelectedItem.selected = NO;
		mSelectedItem = selectedItem;
		selectedItem.selected = YES;
	}
}

#pragma mark - Private methods

- (void)layoutSubviews
{
	[[self.items valueForKey:@"view"] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	
	CGFloat y = NSHeight([self.containerView frame]);
	CGFloat height = NSWidth([self.containerView frame]);
	BOOL showsOverflow = NO;
	for (TabBarItem *item in self.items)
	{
		y -= (height + 12.0f);
		if (y > 0.0f)
		{
			TabBarItemView *view = item.view;
			[self.containerView addSubview:view];
			[view setFrame:NSMakeRect(0.0f, y, height, height)];
		}
		else
		{
			showsOverflow = YES;
			break;
		}
	}
	
	[self.overflowPopUpButton setHidden:!showsOverflow];
	if (showsOverflow)
	{
		NSMenuItem *arrowMenuItem = [[[self.overflowPopUpButton itemAtIndex:0] retain] autorelease];
		[self.overflowPopUpButton removeAllItems];
		[[self.overflowPopUpButton menu] addItem:arrowMenuItem];
		
		for (TabBarItem *item in self.items)
		{
			if ([item.view superview] == nil)
			{
				NSMenuItem *menuItem = [[self.overflowPopUpButton menu] addItemWithTitle:item.title action:@selector(handleOverflowMenuItem:) keyEquivalent:@""];
				[menuItem setTarget:self];
				[menuItem setRepresentedObject:item];
			}
		}
	}
	
	[self setNeedsDisplay:YES];
}

- (void)handleOverflowMenuItem:(id)sender
{
	TabBarItem *item = [sender representedObject];
	[item.target performSelector:item.action withObject:item];
}

@end
