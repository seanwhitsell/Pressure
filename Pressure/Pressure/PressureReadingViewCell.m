//
//  PressureReadingViewCell.m
//  Pressure
//
//  Created by Sean Whitsell on 1/11/12.
//  Copyright (c) 2012 Cisco Systems, Inc. All rights reserved.
//

#import "PressureReadingViewCell.h"
#import <iso646.h>

@implementation PressureReadingViewCell
@synthesize systolicPressureLabel = mSystolicPressureLabel;
@synthesize diastolicPressureLabel = mDiastolicPressureLabel;
@synthesize readingDateLabel = mReadingDateLabel;

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
    
	[super dealloc];
}

#pragma mark -
#pragma mark Reuse

- (void)prepareForReuse
{
	[self.systolicPressureLabel setStringValue:@""];
	[self.diastolicPressureLabel setStringValue:@""];
	[self.readingDateLabel setStringValue:@""];
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect
{
	if([self isSelected]) {
		[[NSColor selectedControlColor] set];
	}
	else {
		[[NSColor whiteColor] set];
    }
    
    //Draw the border and background
	NSBezierPath *roundedRect = [NSBezierPath bezierPathWithRoundedRect:[self bounds] xRadius:6.0 yRadius:6.0];
	[roundedRect fill];
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
