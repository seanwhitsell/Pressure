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
//  Created by Sean Whitsell on 3/9/12.
//

#import "SWDatePicker.h"

@interface SWDatePicker()

@property (nonatomic, readwrite, assign) NSInteger maxMonths;
@property (nonatomic, readwrite, assign) NSInteger mouseDownIndex;
@property (nonatomic, readwrite, retain) NSString *dateRangeLabel;
@property (nonatomic, readwrite, assign) NSInteger hightlightMonthUnderMouse;
@property (nonatomic, readwrite, retain) NSTrackingArea *trackingArea;

- (NSInteger)maxMonths;
- (NSInteger)indexForPoint:(NSPoint)point;
- (NSDate*)firstDayOfMonthForIndex:(NSInteger)index;
- (BOOL)shouldDisplayYearForIndex:(NSInteger)index;
- (NSPoint)pointOfMonthAtIndex:(NSInteger)position highlighted:(BOOL)hightlighted;
- (NSPoint)pointOfYearAtIndex:(NSInteger)position highlighted:(BOOL)hightlighted;
- (NSPoint)pointOfTextAtIndex:(NSInteger)position highlighted:(BOOL)hightlighted;
- (NSString*)formattedDateString;
- (BOOL)shouldDrawMonthforIndex:(NSInteger)index;

@end

@implementation SWDatePicker

@synthesize rangeStartDate = mRangeStartDate;
@synthesize rangeEndDate = mRangeEndDate;
@synthesize displayedStartDate = mDisplayedStartDate;
@synthesize displayedEndDate = mDisplayedEndDate;
@synthesize selectedStartDate = mSelectedStartDate;
@synthesize selectedEndDate = mSelectedEndDate;
@synthesize monthImage = mMonthImage;
@synthesize monthHightlightedImage = mMonthHightlightedImage;
@synthesize monthSelectedImage = mMonthSelectedImage;
@synthesize delegate = mDelegate;
@synthesize maxMonths = mMaxMonths;
@synthesize mouseDownIndex = mMouseDownIndex;
@synthesize dateRangeLabel = mDateRangeLabel;
@synthesize hightlightMonthUnderMouse = mHightlightMonthUnderMouse;
@synthesize trackingArea = mTrackingArea;
@synthesize justification = mJustification;

#pragma mark Object Lifecycle Routines

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        mMonthImage = [NSImage imageNamed:@"MonthCell.png"];
        mMonthHightlightedImage = [NSImage imageNamed:@"MonthCellHighlighted.png"];
        mRangeStartDate = [[NSDate dateWithTimeIntervalSinceNow:0] retain];
        mRangeEndDate = [[NSDate dateWithTimeIntervalSinceNow:0] retain];
        mSelectedStartDate = [[NSDate dateWithTimeIntervalSinceNow:0] retain];
        mSelectedEndDate = [[NSDate dateWithTimeIntervalSinceNow:0] retain];
        mMaxMonths = 0;
        mDelegate = nil;
        mJustification = SWDPJustifiedLeft;
        
        int opts = (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways);
        mTrackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                     options:opts
                                                       owner:self
                                                    userInfo:nil];
        [self addTrackingArea:mTrackingArea];
    }
    
    return self;
}

- (void)dealloc
{
    [mDisplayedStartDate release];
    [mDisplayedEndDate release];
    [mSelectedStartDate release];
    [mSelectedEndDate release];
    
    mDisplayedStartDate = nil;
    mDisplayedEndDate = nil;
    mSelectedStartDate = nil;
    mSelectedEndDate = nil;
    
    [super dealloc];
}

#pragma mark Getters and Setters

- (NSInteger)maxMonths
{
    NSCalendar *gregorian = [[NSCalendar alloc] 
                             initWithCalendarIdentifier:NSGregorianCalendar]; 
    
    NSUInteger unitFlags = NSMonthCalendarUnit | NSDayCalendarUnit; 
    
    NSDateComponents *components = [gregorian components:unitFlags 
                                                fromDate:mRangeStartDate 
                                                  toDate:mRangeEndDate 
                                                 options:0]; 
    
    mMaxMonths = [components month] + 1; 
    
    [gregorian release];
    
    return mMaxMonths;
}

#pragma mark Utility Routines

- (NSInteger)indexForPoint:(NSPoint)point
{
    NSInteger index = -1;
    
    for( NSInteger i=0; i<self.maxMonths; i++ )
    {
        NSPoint p =[self pointOfMonthAtIndex:i highlighted:NO];
        if( point.x > p.x )
        {
            index=i+1;
        }
    }
    
    //
    // Special case: The point is outside the bounds on the right hand side
    NSPoint p =[self pointOfMonthAtIndex:self.maxMonths highlighted:NO];
    if (point.x > p.x)
    {
        index = -1;
    }
    
    //
    // we want to be 0 based index'ed
    if (index > 0)
        index -= 1;
    
    return index;
}

- (NSDate*)firstDayOfMonthForIndex:(NSInteger)index
{
    NSDate *date = nil;
    
    NSCalendar *gregorian = [[NSCalendar alloc] 
                             initWithCalendarIdentifier:NSGregorianCalendar]; 
    
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit; 
    
    NSDateComponents *components = [gregorian components:unitFlags 
                                                fromDate:mRangeStartDate]; 
    
    NSInteger months = [components month];
    [components setMonth:(months + index)];
    [components setDay:1];
    date = [gregorian dateFromComponents:components];
    
    [gregorian release];
    
    return date;
}

- (NSDate*)lastDayOfMonthForIndex:(NSInteger)index
{
    NSDate *date = nil;
    
    NSCalendar *gregorian = [[NSCalendar alloc] 
                             initWithCalendarIdentifier:NSGregorianCalendar]; 
    
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit; 
    
    NSDateComponents *components = [gregorian components:unitFlags 
                                                fromDate:mRangeStartDate]; 
    
    //
    // Figure out the date from the components
    NSInteger months = [components month];
    [components setMonth:(months + index)];
    [components setDay:1];
    date = [gregorian dateFromComponents:components];

    //
    // now that we have a date, let's figure out from teh Gregorian Calendar
    // how many days are in that month
    NSRange daysRange = [gregorian rangeOfUnit:NSDayCalendarUnit
                                        inUnit:NSMonthCalendarUnit
                                       forDate:date];
    
    //
    // Now we create our "end date" from the last day of the month
    [components setDay:daysRange.length];
    date = [gregorian dateFromComponents:components];
    
    [gregorian release];
    
    return date;
}


- (BOOL)shouldDrawMonthforIndex:(NSInteger)index
{
    BOOL retval = YES;
    
    NSPoint point = [self pointOfMonthAtIndex:index highlighted:YES];
    if (point.x < 0.0f)
    {
        retval = NO;
    }
    
    return retval;
}

- (BOOL)shouldDisplayYearForIndex:(NSInteger)index
{
    BOOL retval = NO;
    
    if (index == self.hightlightMonthUnderMouse)
    {
        retval = YES;
    }
    else
    {
        NSCalendar *gregorian = [[NSCalendar alloc] 
                                 initWithCalendarIdentifier:NSGregorianCalendar]; 
        
        NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit; 
        
        NSDateComponents *components = [gregorian components:unitFlags 
                                                    fromDate:[self firstDayOfMonthForIndex:index]]; 
        
        if ([components month] == 1)
        {
            //
            // this is January, so, Yes, we want a year displayed
            retval = YES;
        }
        
        [gregorian release];
        
    }
    
    return retval;
}

- (NSString*)yearStringForIndex:(NSInteger)index
{
    NSCalendar *gregorian = [[NSCalendar alloc] 
                             initWithCalendarIdentifier:NSGregorianCalendar]; 
    
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit; 
    
    NSDateComponents *components = [gregorian components:unitFlags 
                                                fromDate:[self firstDayOfMonthForIndex:index]]; 

    [gregorian release];
    
    return [NSString stringWithFormat:@"%ld",[components year]];
}

-(NSPoint)pointOfMonthAtIndex:(NSInteger)index highlighted:(BOOL)hightlighted
{
    NSSize size = hightlighted?self.monthHightlightedImage.size:self.monthImage.size;    
    CGFloat x = 0.0f;
    CGFloat y = 0.0f;
    
    if (self.justification == SWDPJustifiedLeft)
    {
        x = size.width*index;
    }
    else
    {
        x = self.bounds.size.width - size.width*(self.maxMonths - index);
    }
    
    y = 0.0f;
    
    return NSMakePoint(x,y); 
}

-(NSPoint)pointOfYearAtIndex:(NSInteger)position highlighted:(BOOL)hightlighted
{
    NSSize size = hightlighted?self.monthHightlightedImage.size:self.monthImage.size;    
    CGFloat x = 0.0f;
    CGFloat y = 0.0f;
    
    if (self.justification == SWDPJustifiedLeft)
    {
        x = size.width *  position + 4;
    }
    else
    {
        x = self.bounds.size.width - size.width*(self.maxMonths - position) + 4;
    }
    
    y = 0.0f; 
    
    return NSMakePoint(x,y); 
}

-(NSPoint)pointOfTextAtIndex:(NSInteger)position highlighted:(BOOL)hightlighted
{
    NSSize size = hightlighted?self.monthHightlightedImage.size:self.monthImage.size;    
    CGFloat x = 0.0f;
    CGFloat y = 0.0f;
    
    if (self.justification == SWDPJustifiedLeft)
    {
        x = size.width * position + 4;
    }
    else
    {
        x = self.bounds.size.width - size.width*(self.maxMonths - position) + 4;
    }
    
    y = 10.0f; 
    
    return NSMakePoint(x  ,y); 
}

- (NSString *)stringForIndex:(NSInteger)index
{
    //
    // The Index is a zero based number starting at the mRangeStartDate
    // We will return a 3 character Month for that index
    NSString *retval = nil;
    NSDate *startDate = [self firstDayOfMonthForIndex:index];
    
    NSCalendar *gregorian = [[NSCalendar alloc] 
                             initWithCalendarIdentifier:NSGregorianCalendar]; 
    
    NSUInteger unitFlags = NSMonthCalendarUnit | NSDayCalendarUnit; 
    
    NSDateComponents *components = [gregorian components:unitFlags fromDate:startDate]; 
    NSInteger startMonth = [components month];
    
    switch (startMonth) {
        case 1:
            retval = @"Jan";
            break;
        case 2:
            retval = @"Feb";
            break;
        case 3:
            retval = @"Mar";
            break;
        case 4:
            retval = @"Apr";
            break;
        case 5:
            retval = @"May";
            break;
        case 6:
            retval = @"Jun";
            break;
        case 7:
            retval = @"Jul";
            break;
        case 8:
            retval = @"Aug";
            break;
        case 9:
            retval = @"Sep";
            break;
        case 10:
            retval = @"Oct";
            break;
        case 11:
            retval = @"Nov";
            break;
        case 12:
            retval = @"Dec";
            break;
           
        default:
            break;
    }
    
    [gregorian release];
    
    return retval;
}

- (BOOL)isSelectedIndex:(NSInteger)index
{
    BOOL retval = NO;
    
    if (index == self.hightlightMonthUnderMouse)
    {
        retval = YES;
    }
    else
    {
        NSDate *indexDate = [self firstDayOfMonthForIndex:index];
        
        //
        // Let's see if the date is greater than the start date and less than the end date
        //
        if ((NSOrderedDescending == [indexDate compare:self.selectedStartDate]) ||
            (NSOrderedSame == [indexDate compare:self.selectedStartDate]))
        {
            if ((NSOrderedAscending == [indexDate compare:self.selectedEndDate]) ||
                (NSOrderedSame == [indexDate compare:self.selectedEndDate]))
            {
                retval = YES;
            }
        }
    }
    
    return retval;
}

- (NSString*)formattedDateString
{
    NSDateFormatter *dateFormatStart = [[NSDateFormatter alloc] init];
    NSDateFormatter *dateFormatEnd = [[NSDateFormatter alloc] init];
    NSCalendar *gregorian = [[NSCalendar alloc] 
                             initWithCalendarIdentifier:NSGregorianCalendar];     
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit; 
    
    NSDateComponents *componentsStart = [gregorian components:unitFlags 
                                                     fromDate:self.selectedStartDate]; 
    NSDateComponents *componentsEnd = [gregorian components:unitFlags 
                                                   fromDate:self.selectedEndDate]; 
    
    [dateFormatEnd setDateFormat:@"MMMM YYYY"];
    
    if ([componentsEnd year] == [componentsStart year])
    {
        [dateFormatStart setDateFormat:@"MMMM"];
    }
    else
    {
        [dateFormatStart setDateFormat:@"MMMM YYYY"];
    }
    
    NSString *dateString = [NSString stringWithFormat:@"%@ - %@", [dateFormatStart stringFromDate:self.selectedStartDate], [dateFormatEnd stringFromDate:self.selectedEndDate]];  
    [dateFormatStart release];
    [dateFormatEnd release];
    [gregorian release];    
    
    return dateString;
}

#pragma mark NSView Routines

- (void)drawRect:(NSRect)dirtyRect
{
    NSColor *colorToDraw = [NSColor clearColor];
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:self.bounds];
    NSSize monthSize = [self.monthImage size];
    NSSize monthHighlightedSize = [self.monthHightlightedImage size];
    NSMutableDictionary *stringAttributesBlack12Point = nil;
    NSMutableDictionary *stringAttributesGray8Point = nil;
    NSMutableDictionary *stringAttributesGray12Point = nil;
    NSMutableDictionary *stringAttributesGray16Point = nil;
    NSMutableDictionary *stringAttributesLightGray8Point = nil;

    stringAttributesLightGray8Point = [NSMutableDictionary dictionaryWithCapacity:2];
    [stringAttributesLightGray8Point setObject:[NSFont messageFontOfSize:8.0] forKey:NSFontAttributeName];
    [stringAttributesLightGray8Point setObject:[NSColor lightGrayColor] forKey:NSForegroundColorAttributeName];

    stringAttributesGray12Point = [NSMutableDictionary dictionaryWithCapacity:2];
    [stringAttributesGray12Point setObject:[NSFont messageFontOfSize:12.0] forKey:NSFontAttributeName];
    [stringAttributesGray12Point setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];

    stringAttributesGray8Point = [NSMutableDictionary dictionaryWithCapacity:2];
    [stringAttributesGray8Point setObject:[NSFont messageFontOfSize:8.0] forKey:NSFontAttributeName];
    [stringAttributesGray8Point setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];

    stringAttributesBlack12Point = [NSMutableDictionary dictionaryWithCapacity:2];
    [stringAttributesBlack12Point setObject:[NSFont messageFontOfSize:12.0] forKey:NSFontAttributeName];
    [stringAttributesBlack12Point setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];

    stringAttributesGray16Point = [NSMutableDictionary dictionaryWithCapacity:2];
    [stringAttributesGray16Point setObject:[NSFont messageFontOfSize:16.0] forKey:NSFontAttributeName];
    [stringAttributesGray16Point setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];

    [colorToDraw set];
    [path fill];
    
   for( NSInteger i=0 ; i<self.maxMonths; i++ )
    {
        if ([self shouldDrawMonthforIndex:i])
        {
            if ([self isSelectedIndex:i])
            {
                [self.monthHightlightedImage drawAtPoint:[self pointOfMonthAtIndex:i highlighted:YES] 
                                    fromRect:NSMakeRect(0.0, 0.0, monthHighlightedSize.width, monthHighlightedSize.height) 
                                   operation:NSCompositeSourceOver 
                                    fraction:1.0];
                [[self stringForIndex:i] drawAtPoint:[self pointOfTextAtIndex:i highlighted:YES] withAttributes:stringAttributesBlack12Point];
                
                if ([self shouldDisplayYearForIndex:i])
                {
                    [[self yearStringForIndex:i] drawAtPoint:[self pointOfYearAtIndex:i highlighted:YES] withAttributes:stringAttributesGray8Point];
                }
            }
            else
            {
                [self.monthImage drawAtPoint:[self pointOfMonthAtIndex:i highlighted:NO] 
                                    fromRect:NSMakeRect(0.0, 0.0, monthSize.width, monthSize.height) 
                                   operation:NSCompositeSourceOver 
                                    fraction:1.0];
                [[self stringForIndex:i] drawAtPoint:[self pointOfTextAtIndex:i highlighted:NO] withAttributes:stringAttributesGray12Point];

                if ([self shouldDisplayYearForIndex:i])
                {
                    [[self yearStringForIndex:i] drawAtPoint:[self pointOfYearAtIndex:i highlighted:NO] withAttributes:stringAttributesLightGray8Point];
                }
            }
        }
    }
    

    self.dateRangeLabel = [self formattedDateString];
    [[self dateRangeLabel] drawAtPoint:NSMakePoint(0.0f,45.0f) withAttributes:stringAttributesGray16Point];
}

#pragma mark NSControl Routines

-(void)mouseDown:(NSEvent *)theEvent
{
    if ([theEvent type] == NSLeftMouseDown) 
    {
        //
        // Left mouse down will clear the old selection and start a new selection
        //
        NSPoint pointInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSInteger index = [self indexForPoint:pointInView];
        
        if (index >= 0)
        {
            //
            // This will be the new Start Date.
            self.selectedStartDate = [self firstDayOfMonthForIndex:index];
            self.selectedEndDate = [self lastDayOfMonthForIndex:index];
            self.mouseDownIndex = index;
            
            NSLog(@"mouseDown: index %ld, startDate %@, endDate %@", index, self.selectedStartDate, self.selectedEndDate);
        
            [self setNeedsDisplay];
            
            if(self.delegate && [self.delegate respondsToSelector:@selector(dateRangeSelectionChanged:selectedStartDate:selectedEndDate:)])
            {
                [self.delegate dateRangeSelectionChanged:self 
                                       selectedStartDate:self.selectedStartDate 
                                         selectedEndDate:self.selectedEndDate];
            }
        }
    }
    
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint pointInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger index = [self indexForPoint:pointInView];
    
//    NSLog(@"mouseDragged: index %ld, startDate %@, endDate %@, mouseDownIndex %ld", index, self.selectedStartDate, self.selectedEndDate, self.mouseDownIndex);
    if (index <= self.mouseDownIndex)
    {
        // We are dragging Left
        self.selectedStartDate = [self firstDayOfMonthForIndex:index];;
        [self setNeedsDisplay];
        if(self.delegate && [self.delegate respondsToSelector:@selector(dateRangeSelectionChanged:selectedStartDate:selectedEndDate:)])
        {
            [self.delegate dateRangeSelectionChanged:self 
                                   selectedStartDate:self.selectedStartDate 
                                     selectedEndDate:self.selectedEndDate];
        }
    }

    if (index >= self.mouseDownIndex)
    {
        // We are dragging Right
        self.selectedEndDate = [self lastDayOfMonthForIndex:index];
        [self setNeedsDisplay];
        if(self.delegate && [self.delegate respondsToSelector:@selector(dateRangeSelectionChanged:selectedStartDate:selectedEndDate:)])
        {
            [self.delegate dateRangeSelectionChanged:self 
                                   selectedStartDate:self.selectedStartDate 
                                     selectedEndDate:self.selectedEndDate];
        }
    }
}

-(void)mouseUp:(NSEvent *)theEvent
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(dateRangeSelectionChanged:selectedStartDate:selectedEndDate:)])
    {
        [self.delegate dateRangeSelectionChanged:self 
                               selectedStartDate:self.selectedStartDate 
                                 selectedEndDate:self.selectedEndDate];
    }
}

- (void)mouseMoved:(NSEvent *)theEvent
{
//	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
    
    NSPoint pointInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger index = [self indexForPoint:pointInView];
    
    self.hightlightMonthUnderMouse = index;
    [self setNeedsDisplay: YES];
    
}

- (void)mouseEntered:(NSEvent*)theEvent
{

    NSPoint pointInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger index = [self indexForPoint:pointInView];

    if (index < 0)
    {
        // Mouse enter was outside of our valid months
    }
    else
    {
        self.hightlightMonthUnderMouse = index;
        [self setNeedsDisplay: YES];
    }
}

- (void)mouseExited:(NSEvent*)theEvent
{
//	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);

    self.hightlightMonthUnderMouse = -1;
    [self setNeedsDisplay: YES];
}
@end
