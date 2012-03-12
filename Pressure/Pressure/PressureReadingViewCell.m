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
//  PressureReadingViewCell.m
//  Pressure
//
//  Created by Sean Whitsell on 1/11/12.
//

#import "PressureReadingViewCell.h"
#import <iso646.h>
#import <objc/runtime.h>

@implementation PressureReadingViewCell
@synthesize systolicPressureLabel = mSystolicPressureLabel;
@synthesize diastolicPressureLabel = mDiastolicPressureLabel;
@synthesize readingDateLabel = mReadingDateLabel;
@synthesize heartRateLabel = mHeartRateLabel;
@synthesize excludeCheckBox = mExcludeCheckBox;
@synthesize databankName = mDatabankName;

#pragma mark -
#pragma mark Init/Dealloc

- (id)initWithReusableIdentifier: (NSString*)identifier
{
	if((self = [super initWithReusableIdentifier:identifier]))
	{
	}
	
	return self;
}

- (void)dealloc
{
	[mSystolicPressureLabel release], mSystolicPressureLabel=nil;
	[mDiastolicPressureLabel release], mDiastolicPressureLabel=nil;
	[mReadingDateLabel release], mReadingDateLabel=nil;
    [mHeartRateLabel release], mHeartRateLabel=nil;
    [mDatabankName release], mDatabankName=nil;
    
	[super dealloc];
}

#pragma mark -
#pragma mark Reuse

- (void)prepareForReuse
{
	[self.systolicPressureLabel setStringValue:@""];
	[self.diastolicPressureLabel setStringValue:@""];
	[self.readingDateLabel setStringValue:@""];
    [self.heartRateLabel setStringValue:@""];
    [self.databankName setStringValue:@""];
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect
{
	NSColor *backgroundColor = nil;
	if (self.isSelected)
	{
		if ([[self window] isKeyWindow])
		{
			backgroundColor = [NSColor alternateSelectedControlColor];
		}
		else
		{
			backgroundColor = [NSColor secondarySelectedControlColor];
		}
	}
	else
	{
		NSArray *colors = [NSColor controlAlternatingRowBackgroundColors];
		NSUInteger index = self.row % [colors count];
		backgroundColor = [colors objectAtIndex:index];
	}
	
	[backgroundColor set];
	NSRectFill([self bounds]);
	
	for (NSView *subview in [self subviews])
	{
		if ([subview isKindOfClass:[NSTextField class]])
		{
			static char textColorKey;
			NSTextField *textField = (NSTextField *)subview;
			NSColor *textColor = objc_getAssociatedObject(textField, &textColorKey);
			if (textColor == nil)
			{
				textColor = [textField textColor];
				objc_setAssociatedObject(textField, &textColorKey, textColor, OBJC_ASSOCIATION_RETAIN);
			}
			
			if (self.isSelected && [[self window] isKeyWindow])
			{
				[textField setTextColor:[NSColor highlightColor]];
			}
			else
			{
				[textField setTextColor:textColor];
			}
		}
	}
}


#pragma mark -
#pragma mark Accessibility

- (NSArray*)accessibilityAttributeNames
{
	NSMutableArray*	attribs = [[[super accessibilityAttributeNames] mutableCopy] autorelease];
	
	[attribs addObject: NSAccessibilityRoleAttribute];
	[attribs addObject: NSAccessibilityDescriptionAttribute];
	[attribs addObject: NSAccessibilityTitleAttribute];
	[attribs addObject: NSAccessibilityEnabledAttribute];
	
	return attribs;
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute
{
	if( [attribute isEqualToString: NSAccessibilityRoleAttribute]
       or [attribute isEqualToString: NSAccessibilityDescriptionAttribute]
       or [attribute isEqualToString: NSAccessibilityTitleAttribute]
       or [attribute isEqualToString: NSAccessibilityEnabledAttribute] )
	{
		return NO;
	}
	else
		return [super accessibilityIsAttributeSettable: attribute];
}

- (id)accessibilityAttributeValue:(NSString*)attribute
{
	if([attribute isEqualToString:NSAccessibilityRoleAttribute])
	{
		return NSAccessibilityButtonRole;
	}
	
    if([attribute isEqualToString:NSAccessibilityDescriptionAttribute]
       or [attribute isEqualToString:NSAccessibilityTitleAttribute])
	{
		return [self.systolicPressureLabel stringValue];
	}
    
	if([attribute isEqualToString:NSAccessibilityEnabledAttribute])
	{
		return [NSNumber numberWithBool:YES];
	}
    
    return [super accessibilityAttributeValue:attribute];
}

@end
