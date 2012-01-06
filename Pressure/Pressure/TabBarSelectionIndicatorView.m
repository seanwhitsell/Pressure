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
//  TabBarSelectionIndicatorView.m
//  Created by Ben Shanfelder on 1/5/12.
//

#import "TabBarSelectionIndicatorView.h"

@implementation TabBarSelectionIndicatorView

- (void)drawRect:(NSRect)dirtyRect
{
	[[[NSColor whiteColor] colorWithAlphaComponent:0.25f] set];
	[[NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds], 2.0f, 2.0f) xRadius:4.0f yRadius:4.0f] fill];
	
	[super drawRect:dirtyRect];
}

@end
