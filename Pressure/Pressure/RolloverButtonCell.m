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
//  RolloverButtonCell.m
//  Created by Ben Shanfelder on 1/8/12.
//

#import "RolloverButtonCell.h"

@interface RolloverButtonCell ()

- (void)completeInit;

- (void)windowDidBecomeKey:(NSNotification *)notification;
- (void)windowDidResignKey:(NSNotification *)notification;

@end

@implementation RolloverButtonCell

- (id)initImageCell:(NSImage *)image
{
	self = [super initImageCell:image];
	if (self != nil)
	{
		[self completeInit];
	}
	
	return self;
}

- (id)initTextCell:(NSString *)string
{
	self = [super initTextCell:string];
	if (self != nil)
	{
		[self completeInit];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	if (self != nil)
	{
		[self completeInit];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (NSBezelStyle)bezelStyle
{
	return NSRecessedBezelStyle;
}

- (BOOL)showsBorderOnlyWhileMouseInside
{
	return YES;
}

- (BOOL)isBordered
{
	return YES;
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	NSBezierPath *bezierPath = [NSBezierPath bezierPathWithOvalInRect:frame];
	
	if ([self isHighlighted] && ([self highlightsBy] != NSNoCellMask))
	{
		[[NSColor darkGrayColor] set];
		[bezierPath fill];
	}
	else if ([self state] && ([self showsStateBy] != NSNoCellMask))
	{
		[[NSColor darkGrayColor] set];
		[bezierPath fill];
	}
	else
	{
		if ([[controlView window] isKeyWindow])
		{
			[[NSColor grayColor] set];
		}
		else
		{
			[[NSColor lightGrayColor] set];
		}
		
		[bezierPath fill];
	}
}

#pragma mark - Private methods

- (void)completeInit
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:nil];
	[nc addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:nil];
}

#pragma mark - NSWindow notifications

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	if ([notification object] == [[self controlView] window])
	{
		[[self controlView] setNeedsDisplay:YES];
	}
}

- (void)windowDidResignKey:(NSNotification *)notification
{
	if ([notification object] == [[self controlView] window])
	{
		[[self controlView] setNeedsDisplay:YES];
	}
}

@end
