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

- (void)updateImage;

@end

@implementation SyncButton

@synthesize syncing = mSyncing;

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
		[self updateImage];
	}
	
	return self;
}

- (void)setSyncing:(BOOL)syncing
{
	if (syncing != mSyncing)
	{
		mSyncing = syncing;
		[self updateImage];
	}
}

#pragma mark - Private methods

- (void)updateImage
{
	if (self.isSyncing)
	{
		NSImage *image = [NSImage imageNamed:@"x_close"];
		[image setSize:NSMakeSize(10.0f, 10.0f)];
		[image setTemplate:YES];
		[self setImage:image];
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
