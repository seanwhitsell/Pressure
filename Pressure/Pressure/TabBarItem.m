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
//  TabBarItem.m
//  Created by Ben Shanfelder on 1/4/12.
//

#import "TabBarItem.h"

@implementation TabBarItem

@synthesize image = mImage;
@synthesize finishedSelectedImage = mFinishedSelectedImage;
@synthesize title = mTitle;
@synthesize tag = mTag;
@synthesize badgeValue = mBadgeValue;

@synthesize target = mTarget;
@synthesize action = mAction;
@synthesize selected = mSelected;

@synthesize view = mView;

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		if ([NSBundle loadNibNamed:@"TabBarItem" owner:self])
		{
		}
	}
	
	return self;
}

- (void)dealloc
{
	[mImage release];
	mImage = nil;
	
	[mFinishedSelectedImage release];
	mFinishedSelectedImage = nil;
	
	[mTitle release];
	mTitle = nil;
	
	[mBadgeValue release];
	mBadgeValue = nil;
	
	// not retained
	mTarget = nil;
	
	[mView release];
	mView = nil;
	
	[super dealloc];
}

- (void)setImage:(NSImage *)image
{
	if (image != mImage)
	{
		[image retain];
		[mImage release];
		mImage = image;
		
		if (!NSEqualSizes([image size], NSZeroSize))
		{
			NSRect imageRect = NSMakeRect(0.0f, 0.0f, [image size].width, [image size].height);
			
			NSImage *overlayImage = [[[NSImage alloc] initWithSize:[image size]] autorelease];
			[overlayImage lockFocus];
			NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor whiteColor] endingColor:[NSColor blueColor]] autorelease];
			[gradient drawInRect:imageRect angle:45.0f];
			[overlayImage unlockFocus];
			
			NSImage *tempImage = [[[NSImage alloc] initWithSize:[image size]] autorelease];
			[tempImage lockFocus];
			[image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
			[overlayImage drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceIn fraction:1.0f];
			[tempImage unlockFocus];
			
			NSImage *finishedSelectedImage = [[[NSImage alloc] initWithSize:[image size]] autorelease];
			[finishedSelectedImage lockFocus];
			NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
			[shadow setShadowOffset:NSMakeSize(3.0f, -6.0f)];
			[shadow setShadowBlurRadius:8.0f];
			[shadow setShadowColor:[NSColor shadowColor]];
			[shadow set];
			[tempImage drawInRect:NSMakeRect(0.0f, 0.0f, [self.image size].width, [self.image size].height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
			[finishedSelectedImage unlockFocus];
			
			self.finishedSelectedImage = finishedSelectedImage;
		}
	}
}

+ (NSSet *)keyPathsForValuesAffectingCurrentImage
{
	return [NSSet setWithObjects:@"image", @"selected", nil];
}

- (NSImage *)currentImage
{
	return self.isSelected ? self.finishedSelectedImage : self.image;
}

#pragma mark - Private methods

- (IBAction)handleButton:(id)sender
{
	[self.target performSelector:self.action withObject:self];
}

@end
