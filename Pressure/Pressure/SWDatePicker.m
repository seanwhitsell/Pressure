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
    
    return mMaxMonths;
}

#pragma mark Utility Routines

- (NSInteger)indexForPoint:(NSPoint)point
{
    NSInteger index = 0;
    
    for( NSInteger i=0; i<self.maxMonths; i++ )
    {
        NSPoint p =[self pointOfMonthAtIndex:i highlighted:NO];
        if( point.x > p.x )
        {
            index=i+1;
        }
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
    
    return date;
}

- (BOOL)shouldDisplayYearForIndex:(NSInteger)index
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
        return YES;
    }
    
    return NO;
}

- (NSString*)yearStringForIndex:(NSInteger)index
{
    NSCalendar *gregorian = [[NSCalendar alloc] 
                             initWithCalendarIdentifier:NSGregorianCalendar]; 
    
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit; 
    
    NSDateComponents *components = [gregorian components:unitFlags 
                                                fromDate:[self firstDayOfMonthForIndex:index]]; 

    return [NSString stringWithFormat:@"%ld",[components year]];
}

-(NSPoint)pointOfMonthAtIndex:(NSInteger)index highlighted:(BOOL)hightlighted
{
    NSSize size = hightlighted?self.monthHightlightedImage.size:self.monthImage.size;    
    CGFloat x = 0.0f;
    CGFloat y = 0.0f;
    
    x = self.bounds.size.width - size.width*(self.maxMonths - index);
    y = 0.0f; //(self.bounds.size.height - size.height)/2.0;
    
    return NSMakePoint(x,y); 
}

-(NSPoint)pointOfYearAtIndex:(NSInteger)position highlighted:(BOOL)hightlighted
{
    NSSize size = hightlighted?self.monthHightlightedImage.size:self.monthImage.size;    
    CGFloat x = 0.0f;
    CGFloat y = 0.0f;
    
    x = self.bounds.size.width - size.width*(self.maxMonths - position) + 4;
    y = 0.0f; //(self.bounds.size.height - size.height)/2.0;
    
    return NSMakePoint(x,y); 
}

-(NSPoint)pointOfTextAtIndex:(NSInteger)position highlighted:(BOOL)hightlighted
{
    NSSize size = hightlighted?self.monthHightlightedImage.size:self.monthImage.size;    
    CGFloat x = 0.0f;
    CGFloat y = 0.0f;
    
    x = self.bounds.size.width - size.width*(self.maxMonths - position) + 4;
    y = 10.0f; //(self.bounds.size.height - 20.0)/2.0;
    
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
    
    return retval;
}

- (BOOL)isSelectedIndex:(NSInteger)index
{
    BOOL retval = NO;
    
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
    
    return dateString;
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

#pragma mark NSView Routines

- (void)drawRect:(NSRect)dirtyRect
{
    NSColor *colorToDraw = [NSColor clearColor];
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:self.bounds];
    NSSize monthSize = [self.monthImage size];
    NSSize monthHighlightedSize = [self.monthHightlightedImage size];
    NSMutableDictionary *stringAttributes = nil;

    [colorToDraw set];
    [path fill];
    
   for( NSInteger i=0 ; i<self.maxMonths; i++ )
    {
        NSLog(@"drawRect isSelectedIndex:%ld is %i", i, [self isSelectedIndex:i] );
        if ([self shouldDrawMonthforIndex:i])
        {
            if ([self isSelectedIndex:i])
            {
                [self.monthHightlightedImage drawAtPoint:[self pointOfMonthAtIndex:i highlighted:YES] 
                                    fromRect:NSMakeRect(0.0, 0.0, monthHighlightedSize.width, monthHighlightedSize.height) 
                                   operation:NSCompositeSourceOver 
                                    fraction:1.0];
                stringAttributes = [NSMutableDictionary dictionaryWithCapacity:2];
                [stringAttributes setObject:[NSFont messageFontOfSize:12.0] forKey:NSFontAttributeName];
                [stringAttributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
                [[self stringForIndex:i] drawAtPoint:[self pointOfTextAtIndex:i highlighted:YES] withAttributes:stringAttributes];
                
                if ([self shouldDisplayYearForIndex:i])
                {
                    stringAttributes = [NSMutableDictionary dictionaryWithCapacity:2];
                    [stringAttributes setObject:[NSFont messageFontOfSize:8.0] forKey:NSFontAttributeName];
                    [stringAttributes setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
                    [[self yearStringForIndex:i] drawAtPoint:[self pointOfYearAtIndex:i highlighted:YES] withAttributes:stringAttributes];
                }
            }
            else
            {
                [self.monthImage drawAtPoint:[self pointOfMonthAtIndex:i highlighted:NO] 
                                    fromRect:NSMakeRect(0.0, 0.0, monthSize.width, monthSize.height) 
                                   operation:NSCompositeSourceOver 
                                    fraction:1.0];
                stringAttributes = [NSMutableDictionary dictionaryWithCapacity:2];
                [stringAttributes setObject:[NSFont messageFontOfSize:12.0] forKey:NSFontAttributeName];
                [stringAttributes setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
                [[self stringForIndex:i] drawAtPoint:[self pointOfTextAtIndex:i highlighted:NO] withAttributes:stringAttributes];

                if ([self shouldDisplayYearForIndex:i])
                {
                    stringAttributes = [NSMutableDictionary dictionaryWithCapacity:2];
                    [stringAttributes setObject:[NSFont messageFontOfSize:8.0] forKey:NSFontAttributeName];
                    [stringAttributes setObject:[NSColor lightGrayColor] forKey:NSForegroundColorAttributeName];
                    [[self yearStringForIndex:i] drawAtPoint:[self pointOfYearAtIndex:i highlighted:NO] withAttributes:stringAttributes];
                }
            }
        }
    }
    
    stringAttributes = [NSMutableDictionary dictionaryWithCapacity:2];
    [stringAttributes setObject:[NSFont messageFontOfSize:16.0] forKey:NSFontAttributeName];
    [stringAttributes setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];

    self.dateRangeLabel = [self formattedDateString];
    [[self dateRangeLabel] drawAtPoint:NSMakePoint(8.0f,40.0f) withAttributes:stringAttributes];
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
        
        //
        // This will be the new Start Date.
        self.selectedStartDate = [self firstDayOfMonthForIndex:index];
        self.selectedEndDate = [self lastDayOfMonthForIndex:index];
        self.mouseDownIndex = index;
        
        NSLog(@"mouseDown: index %ld, startDate %@, endDate %@", index, self.selectedStartDate, self.selectedEndDate);
    
        [self setNeedsDisplay];
    }
    
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint pointInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger index = [self indexForPoint:pointInView];
    
    NSDate *temp = [self firstDayOfMonthForIndex:index];
    NSLog(@"mouseDragged: index %ld, dateForIndex %@, startDate %@, endDate %@", index, temp, self.selectedStartDate, self.selectedEndDate);

    if (index <= self.mouseDownIndex)
    {
        // We are dragging Left
        self.selectedStartDate = temp;
    }
    else
    if (index >= self.mouseDownIndex)
    {
        // We are dragging Right
        self.selectedEndDate = [self lastDayOfMonthForIndex:index];
    }

    [self setNeedsDisplay];
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

@end
