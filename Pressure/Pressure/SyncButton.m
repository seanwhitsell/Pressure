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
//  SyncButton.m
//  Created by Ben Shanfelder on 1/8/12.
//

#import "SyncButton.h"
#import "RolloverButtonCell.h"

@interface SyncButton ()

@property (nonatomic, readwrite, retain) NSTrackingArea *trackingArea;
@property (nonatomic, readwrite, assign, getter=isRollover) BOOL rollover;
@property (nonatomic, readwrite, assign) NSUInteger angle;

- (void)updateImage;

@end

@implementation SyncButton

@synthesize syncing = mSyncing;
@synthesize trackingArea = mTrackingArea;
@synthesize rollover = mRollover;
@synthesize angle = mAngle;

+ (Class)cellClass
{
	return [RolloverButtonCell class];
}

+ (NSSize)frameSize
{
	return NSMakeSize(18.0f, 18.0f);
}

- (id)initWithFrame:(NSRect)frameRect
{
	frameRect.size = [[self class] frameSize];
	self = [super initWithFrame:frameRect];
	if (self != nil)
	{
		[self setBordered:NO];
		
		self.trackingArea = [[[NSTrackingArea alloc] initWithRect:[self bounds] options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil] autorelease];
		[self addTrackingArea:self.trackingArea];
		
		[self updateImage];
	}
	
	return self;
}

- (void)dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	[self removeTrackingArea:mTrackingArea];
	[mTrackingArea release];
	mTrackingArea = nil;
	
	[super dealloc];
}

- (void)mouseEntered:(NSEvent *)event
{
	[super mouseEntered:event];
	self.rollover = YES;
}

- (void)mouseExited:(NSEvent *)event
{
	[super mouseExited:event];
	self.rollover = NO;
}

- (void)setSyncing:(BOOL)syncing
{
	if (syncing != mSyncing)
	{
		mSyncing = syncing;
		self.angle = 0; // Reset the angle here.
		[self updateImage];
	}
}

#pragma mark - Private methods

- (void)setRollover:(BOOL)rollover
{
	if (rollover != mRollover)
	{
		mRollover = rollover;
		[self updateImage];
	}
}

- (void)updateImage
{
	if (self.isSyncing)
	{
		if (self.isRollover)
		{
			NSImage *image = [NSImage imageNamed:@"x_close"];
			[image setSize:NSMakeSize(10.0f, 10.0f)];
			[image setTemplate:YES];
			[self setImage:image];
		}
		else
		{
			NSRect rect = NSMakeRect(0.0f, 0.0f, 14.0f, 14.0f);
			NSImage *image = [[[NSImage alloc] initWithSize:rect.size] autorelease];
			[image lockFocus];
			NSAffineTransform *transform = [NSAffineTransform transform];
			[transform translateXBy:NSMidX(rect) yBy:NSMidY(rect)];
			[transform rotateByDegrees:self.angle]; // Use (360 - self.angle) depending on the direction of the arrow in the image.
			[transform translateXBy:-NSMidX(rect) yBy:-NSMidY(rect)];
			[transform concat];
			
			[[NSImage imageNamed:@"TMRotatingArrow"] drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
			[image unlockFocus];
			[image setTemplate:YES];
			[self setImage:image];
		}
		
		// By not putting these lines in the else clause above, we can give the illusion that the spinner was still spinning during mouseover.
		self.angle = (self.angle + 6) % 360; // Note, the addition controls how fast the arrow spins.
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateImage) object:nil];
		[self performSelector:@selector(updateImage) withObject:nil afterDelay:(1.0 / 30.0) inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	}
	else
	{
		NSImage *image = [NSImage imageNamed:@"TMRotatingArrow"];
		[image setSize:NSMakeSize(14.0f, 14.0f)];
		[image setTemplate:YES];
		[self setImage:image];
	}
}

@end
