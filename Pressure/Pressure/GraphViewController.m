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
//
//  GraphViewController.m
//  Created by Sean Whitsell on 1/8/12.
//

#import "GraphViewController.h"
#import "PXListView.h"
#import "PressureReadingViewCell.h"
#import "OmronDataSource.h"
#import "NSDate+Helper.h"
#import "OmronDataRecord.h"
#import <CorePlot/CorePlot.h>
#import <CorePlot/CPTPlot.h>

NSString *GraphDataPointWasSelectedNotification = @"GraphDataPointWasSelectedNotification";

#define FrequencyDistributionWidth 5

#pragma mark Private Interface

@interface GraphViewController()

@property (nonatomic, readwrite, retain) OmronDataSource *dataSource;
@property (nonatomic, readwrite, retain) NSArray *dataSourceSortedReadings;
@property (nonatomic, readwrite, retain) NSArray *systolicFrequencyDistribution;
@property (nonatomic, readwrite, retain) NSArray *diastolicFrequencyDistribution;
@property (nonatomic, readwrite, retain) NSArray *plotData;
@property (nonatomic, readwrite, retain) CPTXYGraph *graph;
@property (nonatomic, readwrite, retain) CPTXYGraph *systolicGraph;
@property (nonatomic, readwrite, retain) CPTXYGraph *diastolicGraph;
@property (nonatomic, readwrite, retain) CPTLineStyle *barLineStyle;
@property (nonatomic, readwrite, retain) CPTFill *areaFill;
@property (nonatomic, readwrite, retain) CPTScatterPlot *pulseLinePlot;
@property (nonatomic, readwrite, retain) CPTTradingRangePlot *bloodPressureLinePlot;
@property (nonatomic, readwrite, retain) CPTBarPlot *systolicBarPlot;
@property (nonatomic, readwrite, retain) CPTBarPlot *diastolicBarPlot;
@property (nonatomic, readwrite, retain) NSDate *referenceDate;

- (void)dataSyncOperationDidEnd:(NSNotification*)notif;
- (void)dataSyncOperationDataAvailable:(NSNotification*)notif;
- (void)updateSortedReadings;
- (void)recalculateGraphAxis;
- (void)recalculateDatePickerRange;
- (CPTFill *)barFillForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index; 
- (CPTLineStyle *)barLineStyleForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index; 

@end

@implementation GraphViewController

@synthesize dataSource = mDataSource;
@synthesize hostView = mHostView;
@synthesize dataSourceSortedReadings = mDataSourceSortedReadings;
@synthesize graph = mGraph;
@synthesize systolicGraph = mSystolicGraph;
@synthesize diastolicGraph = mDiastolicGraph;
@synthesize plotData = mPlotData;
@synthesize barLineStyle = mBarLineStyle;
@synthesize areaFill = mAreaFill;
@synthesize pulseLinePlot = mPulseLinePlot;
@synthesize bloodPressureLinePlot = mBloodPressureLinePlot;
@synthesize referenceDate = mReferenceDate;
@synthesize backdropView = mBackdropView;
@synthesize systolicFrequencyDistributionView = mSystolicFrequencyDistributionView;
@synthesize diastolicFrequencyDistributionView = mDiastolicFrequencyDistributionView;
@synthesize systolicBarPlot = mSystolicBarPlot;
@synthesize diastolicBarPlot = mDiastolicBarPlot;
@synthesize systolicFrequencyDistribution = mSystolicFrequencyDistribution;
@synthesize diastolicFrequencyDistribution = mDiastolicFrequencyDistribution;
@synthesize datePicker = mDatePicker;

#pragma mark Object Lifecycle Routines

- (id)initWithDatasource:(OmronDataSource*)aDataSource
{
    [self init];
    mDataSource = aDataSource;
    
    return self;
}

- (id)init
{
	self = [super initWithNibName:@"GraphViewController" bundle:nil];
	if (self != nil)
	{
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(dataSyncOperationDidEnd:) 
                                                     name:OmronDataSyncDidEndNotification 
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(dataSyncOperationDataAvailable:) 
                                                     name:OmronDataSyncDataAvailableNotification 
                                                   object:nil];

        NSTimeInterval oneDay = 24 * 60 * 60;
        
        
        // Create Main Graph 
        mGraph = [[CPTXYGraph alloc] initWithFrame:self.view.bounds];
        mHostView.hostedGraph = mGraph;
        
        mGraph.plotAreaFrame.borderLineStyle = nil;
        mGraph.defaultPlotSpace.delegate = (id)self;
        mGraph.plotAreaFrame.paddingTop = 30.0;
        mGraph.plotAreaFrame.paddingLeft = 40.0;
        mGraph.plotAreaFrame.paddingBottom = 60.0;
        mGraph.plotAreaFrame.paddingRight = 30.0;
        
        // Main Graph Title
        CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
        textStyle.color = [CPTColor darkGrayColor];
        textStyle.fontSize = 18.0f;
        textStyle.fontName = @"Helvetica";
        mGraph.title = @"";
        mGraph.titleTextStyle = textStyle;
        mGraph.titleDisplacement = CGPointMake(0.0f, -20.0f);
        
        // Add Pulse line style
        CGFloat values[4]	= { 111.0/255.0, 206.0/255.0, 145.0/255.0, 1.0 };
        CGColorRef colorRef = CGColorCreate([CPTColorSpace genericRGBSpace].cgColorSpace, values);
        CPTColor *pulseColor = [[[CPTColor alloc] initWithCGColor:colorRef] autorelease];
        CGColorRelease(colorRef);
        
        CPTMutableLineStyle *pulseLineStyle = [CPTMutableLineStyle lineStyle];
        pulseLineStyle.lineWidth = 3.0f;
        pulseLineStyle.lineColor = pulseColor;
        
        // Add Pressure line style
        CGFloat values2[4]	= { 39.0/255.0, 193.0/255.0, 219.0/255.0, 1.0 };
        CGColorRef colorRef2 = CGColorCreate([CPTColorSpace genericRGBSpace].cgColorSpace, values2);
        CPTColor *pressureColor = [[[CPTColor alloc] initWithCGColor:colorRef2] autorelease];
        CGColorRelease(colorRef2);
        
        CPTMutableLineStyle *bloodPressureLineStyle = [CPTMutableLineStyle lineStyle];
        bloodPressureLineStyle.lineWidth = 2.0f;
        bloodPressureLineStyle.lineColor = pressureColor;
        
        // Main Graph Axes
        CPTXYAxisSet *axisSet = (CPTXYAxisSet *)mGraph.axisSet;
        CPTXYAxis *x = axisSet.xAxis;
        
        x.majorIntervalLength = CPTDecimalFromFloat(oneDay * 10);
        x.minorTicksPerInterval = 10;
        x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"30");
        x.labelRotation = M_PI/4.0;
        x.axisLineCapMax = [[[CPTLineCap alloc] init] autorelease];
        x.axisLineCapMax.lineCapType = CPTLineCapTypeOpenArrow;
        
        CPTXYAxis *y = axisSet.yAxis;
        y.majorIntervalLength = CPTDecimalFromString(@"10");
        y.minorTicksPerInterval = 0;
        y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0.0f);
        
        NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [numberFormatter setGeneratesDecimalNumbers:NO];
        y.labelFormatter = numberFormatter;
        
        //
        // Create a plot that uses the data for the Heart Rate
        mPulseLinePlot = [[CPTScatterPlot alloc] initWithFrame:mGraph.bounds];
        mPulseLinePlot.identifier = @"Pulse Plot";
        mPulseLinePlot.dataLineStyle = pulseLineStyle;
        mPulseLinePlot.opacity = 0.8f;
        mPulseLinePlot.dataSource = self;  
        mPulseLinePlot.delegate = self;
        
        //
        // Create a plot that uses the data for the Blood Pressure (Systolic/Diastolic)
        mBloodPressureLinePlot = [[CPTTradingRangePlot alloc] initWithFrame:mGraph.bounds];
        mBloodPressureLinePlot.identifier = @"Blood Pressure";
        mBloodPressureLinePlot.lineStyle = bloodPressureLineStyle;
        mBloodPressureLinePlot.plotStyle = CPTTradingRangePlotStyleOHLC;
        mBloodPressureLinePlot.stickLength = 4.0f;
        mBloodPressureLinePlot.dataSource = self;    
        
        //
        // Add plots to the graph
        [mGraph addPlot:mPulseLinePlot];
        [mGraph addPlot:mBloodPressureLinePlot];
        
        //
        // Systolic Frequency Distribution
        mSystolicGraph = [[CPTXYGraph alloc] initWithFrame:self.view.bounds];
        mSystolicFrequencyDistributionView.hostedGraph = mSystolicGraph;
        
        mSystolicGraph.plotAreaFrame.borderLineStyle = nil;
        mSystolicGraph.defaultPlotSpace.delegate = (id)self;
        mSystolicGraph.plotAreaFrame.paddingTop = 10.0;
        mSystolicGraph.plotAreaFrame.paddingLeft = 40.0;
        mSystolicGraph.plotAreaFrame.paddingBottom = 20.0;
        mSystolicGraph.plotAreaFrame.paddingRight = 10.0;
        
        // Systolic Graph Title
        mSystolicGraph.title = @"Systolic Frequency Distribution";
        mSystolicGraph.titleTextStyle = textStyle;
        mSystolicGraph.titleDisplacement = CGPointMake(0.0f, 0.0f);
        
        // Systolic Graph Axes
        axisSet = (CPTXYAxisSet *)mSystolicGraph.axisSet;
        x = axisSet.xAxis;
        
        x.majorIntervalLength = CPTDecimalFromInt(1);
        x.minorTicksPerInterval = 0;
        x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
        x.labelFormatter = numberFormatter;
        
        y = axisSet.yAxis;
        y.majorIntervalLength = CPTDecimalFromInt(10);
        y.minorTicksPerInterval = 4;
        y.orthogonalCoordinateDecimal = CPTDecimalFromInt(0);
        y.labelFormatter = numberFormatter;
        
        mSystolicBarPlot = [[CPTBarPlot alloc] initWithFrame:mSystolicGraph.bounds];
        mSystolicBarPlot.identifier = @"Systolic Bar Plot";
        mSystolicBarPlot.opacity = 0.8f;
        mSystolicBarPlot.dataSource = self;  
        mSystolicBarPlot.delegate = self;
        mSystolicBarPlot.barOffset = CPTDecimalFromFloat(0.5);
        mSystolicBarPlot.barCornerRadius = 6.0f;
        CPTXYPlotSpace *barPlotSpace = (CPTXYPlotSpace *)mSystolicGraph.defaultPlotSpace;
        barPlotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromInt(FrequencyDistributionWidth)];
        barPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromFloat(100.0f)];
        [mSystolicGraph addPlot:mSystolicBarPlot];
        
        //
        // Diastolic Frequency Distribution
        mDiastolicGraph = [[CPTXYGraph alloc] initWithFrame:self.view.bounds];
        mDiastolicFrequencyDistributionView.hostedGraph = mDiastolicGraph;
        
        mDiastolicGraph.plotAreaFrame.borderLineStyle = nil;
        mDiastolicGraph.defaultPlotSpace.delegate = (id)self;
        mDiastolicGraph.plotAreaFrame.paddingTop = 10.0;
        mDiastolicGraph.plotAreaFrame.paddingLeft = 40.0;
        mDiastolicGraph.plotAreaFrame.paddingBottom = 20.0;
        mDiastolicGraph.plotAreaFrame.paddingRight = 10.0;
        
        // Diastolic Graph Title
        mDiastolicGraph.title = @"Diastolic Frequency Distribution";
        mDiastolicGraph.titleTextStyle = textStyle;
        mDiastolicGraph.titleDisplacement = CGPointMake(0.0f, 0.0f);
        
        // Diastolic Graph Axes
        axisSet = (CPTXYAxisSet *)mDiastolicGraph.axisSet;
        x = axisSet.xAxis;
        
        x.majorIntervalLength = CPTDecimalFromInt(1);
        x.minorTicksPerInterval = 0;
        x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
        x.labelFormatter = numberFormatter;
        
        y = axisSet.yAxis;
        y.majorIntervalLength = CPTDecimalFromInt(10);
        y.minorTicksPerInterval = 4;
        y.orthogonalCoordinateDecimal = CPTDecimalFromInt(0);
        y.labelFormatter = numberFormatter;
        
        mDiastolicBarPlot = [[CPTBarPlot alloc] initWithFrame:mDiastolicGraph.bounds];
        mDiastolicBarPlot.identifier = @"Diastolic Bar Plot";
        mDiastolicBarPlot.opacity = 0.8f;
        mDiastolicBarPlot.dataSource = self;  
        mDiastolicBarPlot.delegate = self;
        mDiastolicBarPlot.barOffset = CPTDecimalFromFloat(0.5);
        mDiastolicBarPlot.barCornerRadius = 6.0f;
        barPlotSpace = (CPTXYPlotSpace *)mDiastolicGraph.defaultPlotSpace;
        barPlotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromInt(FrequencyDistributionWidth)];
        barPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromFloat(100.0f)];
        [mDiastolicGraph addPlot:mDiastolicBarPlot];
     
        //
        // Date Picker
        mDatePicker.delegate = self;
        
    }
	
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [mPulseLinePlot release]; mPulseLinePlot = nil;
    [mBloodPressureLinePlot release]; mBloodPressureLinePlot = nil;
    [mGraph release]; mGraph = nil;

    [super dealloc];
}

#pragma mark Utility routines

- (void)updateSortedReadings
{
    // Table Reload
    NSLog(@"[GraphViewController updateSortedReadings]");
    
    //
    // Let's take the data and sort it by date. There is no guarantee that the readings are
    // in any order
    //
    if ([self.dataSource.readings count] > 0)
    {
        self.dataSourceSortedReadings = [self.dataSource.readings sortedArrayUsingComparator:^(id a, id b) {
            NSDate *first = [(OmronDataRecord*)a readingDate];
            NSDate *second = [(OmronDataRecord*)b readingDate];
            return [first compare:second];
        }];
    }
}

- (void)recalculateFrequencyDistributionHistogram
{
    if ([self.dataSource.readings count] > 0)
    {
        //
        // We will have FrequencyDistributionWidth classes for the histogram. 
        // The formula is
        //      W = (L - S) / K
        // where L is the largest data, S is the smallest data, and K is the 
        // number of classes
        //
        // We will create an array of 5 for our classes, calculate W, iterate over 
        // the data and increment the class that each data point calls into.
        //
        OmronDataRecord *record = nil;
        NSInteger K = 0;
        NSInteger L = 0;
        NSInteger S = 0;
        NSInteger W = 0;
        NSInteger highestValue = 0;
        CPTXYPlotSpace *barPlotSpace = nil;
        
        //
        // SYSTOLIC
        //
        NSArray *readingsSortedBySystolicPressure = [self.dataSource.readings sortedArrayUsingComparator:^(id a, id b) {
            NSInteger first = [(OmronDataRecord*)a systolicPressure];
            NSInteger second = [(OmronDataRecord*)b systolicPressure];
            if ( first < second ) {
                return (NSComparisonResult)NSOrderedAscending;
            } else if ( first > second ) {
                return (NSComparisonResult)NSOrderedDescending;
            } else {
                return (NSComparisonResult)NSOrderedSame;
            }
        }];

        record = [readingsSortedBySystolicPressure objectAtIndex:0];

        K = FrequencyDistributionWidth;
        L = [[readingsSortedBySystolicPressure lastObject] systolicPressure];
        S = [[readingsSortedBySystolicPressure objectAtIndex:0] systolicPressure];
        W = (L - S) / K;
        
        if (W*K < L)
        {
            //
            // If there is a remainder for (L-S)/K, then we want to round up
            // on the width
            W++;
        }
        
        NSLog(@"recalculateFrequencyDistributionHistogram - L is %ld, S is %ld W is %ld", L,S,W);
        NSMutableArray *systolicFrequencyDistribution = [[NSMutableArray alloc] initWithCapacity:K];
        
        //
        // Initialize the frequency distribution values
        for (int i=0; i<K; i++) 
        {
            [systolicFrequencyDistribution insertObject:[NSNumber numberWithInt:0] atIndex:i];
        }
        
        highestValue = 0;
        for (OmronDataRecord *record in readingsSortedBySystolicPressure)
        {
            //
            // To put each reading in the frequency distribution, we use this formula
            // Index = (READING - S) / W
            
            NSInteger systolicPressure = [record systolicPressure];
            NSInteger index = (systolicPressure - S) / W;
            int value = [[systolicFrequencyDistribution objectAtIndex:index] intValue];
            value++;
            [systolicFrequencyDistribution replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:value]];
            
            if (value > highestValue)
            {
                highestValue = value;
            }
        }
        
        self.systolicFrequencyDistribution = systolicFrequencyDistribution;
        
        NSLog(@"Systolic Frequency Distribution is %@", self.systolicFrequencyDistribution);
        
        barPlotSpace = (CPTXYPlotSpace*)self.systolicGraph.defaultPlotSpace;
        barPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromFloat(60.0f)];
        barPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromFloat(highestValue + 5.0f)];
        [self.systolicGraph reloadData];
       
        //
        // DIASTOLIC
        //
        NSArray *readingsSortedByDiastolicPressure = [self.dataSource.readings sortedArrayUsingComparator:^(id a, id b) {
            NSInteger first = [(OmronDataRecord*)a diastolicPressure];
            NSInteger second = [(OmronDataRecord*)b diastolicPressure];
            if ( first < second ) {
                return (NSComparisonResult)NSOrderedAscending;
            } else if ( first > second ) {
                return (NSComparisonResult)NSOrderedDescending;
            } else {
                return (NSComparisonResult)NSOrderedSame;
            }
        }];
        
        record = [readingsSortedByDiastolicPressure objectAtIndex:0];
        
        K = FrequencyDistributionWidth;
        L = [[readingsSortedByDiastolicPressure lastObject] diastolicPressure];
        S = [[readingsSortedByDiastolicPressure objectAtIndex:0] diastolicPressure];
        W = (L - S) / K;
        
        if (W*K < L)
        {
            //
            // If there is a remainder for (L-S)/K, then we want to round up
            // on the width
            W++;
        }
        
        NSLog(@"recalculateFrequencyDistributionHistogram - L is %ld, S is %ld W is %ld", L,S,W);
        NSMutableArray *diastolicFrequencyDistribution = [[NSMutableArray alloc] initWithCapacity:K];
        
        //
        // Initialize the frequency distribution values
        for (int i=0; i<K; i++) 
        {
            [diastolicFrequencyDistribution insertObject:[NSNumber numberWithInt:0] atIndex:i];
        }
        
        highestValue = 0;
        for (OmronDataRecord *record in readingsSortedByDiastolicPressure)
        {
            //
            // To put each reading in the frequency distribution, we use this formula
            // Index = (READING - S) / W
            
            NSInteger diastolicPressure = [record diastolicPressure];
            NSInteger index = (diastolicPressure - S) / W;
            int value = [[diastolicFrequencyDistribution objectAtIndex:index] intValue];
            value++;
            [diastolicFrequencyDistribution replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:value]];
            
            if (value > highestValue)
            {
                highestValue = value;
            }
        }
        
        self.diastolicFrequencyDistribution = diastolicFrequencyDistribution;
        
        NSLog(@"Diastolic Frequency Distribution is %@", self.diastolicFrequencyDistribution);
        
        barPlotSpace = (CPTXYPlotSpace*)self.diastolicGraph.defaultPlotSpace;
        barPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromFloat(60.0f)];
        barPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromFloat(highestValue + 5.0f)];
        [self.diastolicGraph reloadData];
    }
}

- (void)recalculateGraphAxis
{
    //
    // We have the list ordered by date, let's get the date of the first
    // record and set teh axis accordingly for the Pressure/Pulse plots
    //
    if ([self.dataSourceSortedReadings count] > 0)
    {
        OmronDataRecord *record = [self.dataSourceSortedReadings objectAtIndex:0];
        self.referenceDate = [record readingDate];
        
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        dateFormatter.dateStyle = kCFDateFormatterShortStyle;
        CPTTimeFormatter *timeFormatter = [[[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter] autorelease];
        timeFormatter.referenceDate = self.referenceDate;
        
        CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
        CPTXYAxis *x = axisSet.xAxis;
        x.labelFormatter = timeFormatter;
        
        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
        
        NSDate *beginning = [[self.dataSourceSortedReadings objectAtIndex:0] readingDate];
        NSDate *ending = [[self.dataSourceSortedReadings objectAtIndex:[self.dataSourceSortedReadings count]-1] readingDate];
        plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-1.0f) length:CPTDecimalFromInteger([ending timeIntervalSinceDate:beginning])];
        plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(30.0) length:CPTDecimalFromFloat(150.0)];
        
        [self.graph reloadData];
    }
}

- (void)recalculateDatePickerRange
{
    self.datePicker.rangeStartDate = [[self.dataSourceSortedReadings objectAtIndex:0] readingDate];
    self.datePicker.rangeEndDate = [NSDate date];
    self.datePicker.displayedStartDate = self.datePicker.rangeStartDate;
    self.datePicker.displayedEndDate = self.datePicker.rangeEndDate;
    
    [self.datePicker setNeedsDisplay];
}

#pragma mark NSViewController methods

- (void)viewWillAppear
{
    [self.backdropView setImage:[NSImage imageNamed:@"backdrop.png"]];
    NSLog(@"[GraphViewController viewWillAppear]");
    [self.graph reloadData];
    [self.systolicGraph reloadData];
    [self.diastolicGraph reloadData];
}

#pragma mark NSResponder events

- (void)swipeWithEvent:(NSEvent *)event 
{
    NSLog(@"Swipe event detected!");
}
- (void)beginGestureWithEvent:(NSEvent *)event 
{
    NSLog(@"beginGestureWithEvent event detected!");
}
- (void)endGestureWithEvent:(NSEvent *)event 
{
    NSLog(@"endGestureWithEvent event detected!");
}

#pragma mark CPTPlotDataSource routines

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    if (plot == self.pulseLinePlot)
    {
        return [self.dataSourceSortedReadings count];
    }
    else if (plot == self.bloodPressureLinePlot)
    {
        return [self.dataSourceSortedReadings count];
    }
    else if (plot == self.systolicBarPlot)
    {
        return FrequencyDistributionWidth;
    }
    else if (plot == self.diastolicBarPlot)
    {
        return FrequencyDistributionWidth;
    }
    
    return 0;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSDecimalNumber *num = [NSDecimalNumber zero];
    OmronDataRecord *record = [self.dataSourceSortedReadings objectAtIndex:index];
    NSDate *readingDate = [record readingDate];
    NSTimeInterval interval = [readingDate timeIntervalSinceDate:self.referenceDate];
    
    if (plot == self.systolicBarPlot)
    {
        switch (fieldEnum) {
            case CPTBarPlotFieldBarLocation:
                num = (NSDecimalNumber *)[NSDecimalNumber numberWithInteger:index];
                NSLog(@"systolicBarPlot CPTBarPlotFieldBarLocation: %d", [num intValue]);
                break;
            case CPTBarPlotFieldBarTip:
                num = [self.systolicFrequencyDistribution objectAtIndex:index];
                NSLog(@"systolicBarPlot CPTBarPlotFieldBarTip: %d", [num intValue]);
                break;
            case CPTBarPlotFieldBarBase:
                num = (NSDecimalNumber *)[NSDecimalNumber numberWithInteger:0];;
                NSLog(@"systolicBarPlot CPTBarPlotFieldBarBase: %d", [num intValue]);
                break;
            default:
                NSLog(@"systolicBarPlot unknown field enum %lu", fieldEnum);
                break;
        }
    }
    else if (plot == self.diastolicBarPlot)
    {
        switch (fieldEnum) {
            case CPTBarPlotFieldBarLocation:
                num = (NSDecimalNumber *)[NSDecimalNumber numberWithInteger:index];
                NSLog(@"diastolicBarPlot CPTBarPlotFieldBarLocation: %d", [num intValue]);
                break;
            case CPTBarPlotFieldBarTip:
                num = [self.diastolicFrequencyDistribution objectAtIndex:index];
                NSLog(@"diastolicBarPlot CPTBarPlotFieldBarTip: %d", [num intValue]);
                break;
            case CPTBarPlotFieldBarBase:
                num = (NSDecimalNumber *)[NSDecimalNumber numberWithInteger:0];;
                NSLog(@"diastolicBarPlot CPTBarPlotFieldBarBase: %d", [num intValue]);
                break;
            default:
                NSLog(@"diastolicBarPlot unknown field enum %lu", fieldEnum);
                break;
        }
        
    }
    else
    if (record)
    {
        if (plot == self.pulseLinePlot)
        {
            switch (fieldEnum) 
            {
                case CPTScatterPlotFieldX:
                    num = (NSDecimalNumber *)[NSDecimalNumber numberWithInteger:interval];
                    break;
                case CPTScatterPlotFieldY: 
                    num = (NSDecimalNumber *) [NSDecimalNumber numberWithLong:[record heartRate]];
                    break;
                default:
                    break;
            }
        }
        else
        if (plot == self.bloodPressureLinePlot)
        {
            switch (fieldEnum) 
            {
                case CPTTradingRangePlotFieldX:
                    num = (NSDecimalNumber *)[NSDecimalNumber numberWithInteger:interval];
                    break;
                    
                case CPTTradingRangePlotFieldClose:
                    num = (NSDecimalNumber *) [NSDecimalNumber numberWithLong:[record diastolicPressure]];
                    break;
                    
                case CPTTradingRangePlotFieldHigh:
                    num = (NSDecimalNumber *) [NSDecimalNumber numberWithLong:[record systolicPressure]];
                    break;
                    
                case CPTTradingRangePlotFieldLow:
                    num = (NSDecimalNumber *) [NSDecimalNumber numberWithLong:[record diastolicPressure]];
                    break;
                    
                case CPTTradingRangePlotFieldOpen:
                    num = (NSDecimalNumber *) [NSDecimalNumber numberWithLong:[record systolicPressure]];
                    break;                    
            }
        }
        else
        {
            NSLog(@"Error - unknown plot");
        }
    }
    else
    {
        NSLog(@"No Record");
    }

    return num;
}

- (CPTPlotSymbol *)symbolForScatterPlot:(CPTScatterPlot *)plot recordIndex:(NSUInteger)index
{
    static CPTPlotSymbol *redDot = nil;
    
    CPTPlotSymbol *symbol = (id)[NSNull null];
    
    CGFloat values[4]	= { 111.0/255.0, 206.0/255.0, 145.0/255.0, 1.0 };
    CGColorRef colorRef = CGColorCreate([CPTColorSpace genericRGBSpace].cgColorSpace, values);
    CPTColor *pulseColor = [[[CPTColor alloc] initWithCGColor:colorRef] autorelease];
    CGColorRelease(colorRef);

    CPTMutableLineStyle *pulseLineStyle = [CPTMutableLineStyle lineStyle];
    pulseLineStyle.lineWidth = 1.0f;
    pulseLineStyle.lineColor = pulseColor;

    if ( [(NSString *)plot.identifier isEqualToString:@"Pulse Plot"]  ) {
        if ( !redDot ) {
            redDot = [[CPTPlotSymbol alloc] init];
            redDot.symbolType = CPTPlotSymbolTypeEllipse;
            redDot.size = CGSizeMake(6.0, 6.0);
            redDot.fill  = [CPTFill fillWithColor:pulseColor];
            redDot.lineStyle = pulseLineStyle;
        }
        symbol = redDot;
    }
    
    return symbol;
}

#pragma mark CPTBarPlotDataSource optional routines

- (CPTFill *)barFillForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index
{
    return [CPTFill fillWithColor:[CPTColor whiteColor]];
}

- (CPTLineStyle *)barLineStyleForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index
{
    return nil;
}

#pragma mark NSNotification Observers

- (void)dataSyncOperationDidEnd:(NSNotification*)notif
{
    [self updateSortedReadings];
    [self recalculateFrequencyDistributionHistogram];
    [self recalculateGraphAxis];
    [self recalculateDatePickerRange];
}

- (void)dataSyncOperationDataAvailable:(NSNotification*)notif
{
    [self updateSortedReadings];
    [self recalculateFrequencyDistributionHistogram];
    [self recalculateGraphAxis];
    [self recalculateDatePickerRange];
}

#pragma mark CPTPlotSpaceDelegate methods

-(BOOL)plotSpace:(CPTPlotSpace*)space shouldScaleBy:(CGFloat)interactionScale aboutPoint:(CGPoint)interactionPoint
{
    NSLog(@"[GraphViewController shouldScaleBy] delegate");
    return YES;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDownEvent:(id)event atPoint:(CGPoint)point 
{
    NSLog(@"[GraphViewController shouldHandlePointingDeviceDownEvent] delegate");
    return YES;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDraggedEvent:(id)event atPoint:(CGPoint)point
{
    NSLog(@"[GraphViewController shouldHandlePointingDeviceDraggedEvent] delegate");
    return YES;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceCancelledEvent:(id)event
{
    NSLog(@"[GraphViewController shouldHandlePointingDeviceCancelledEvent] delegate");
   return YES;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceUpEvent:(id)event atPoint:(CGPoint)point
{
    NSLog(@"[GraphViewController shouldHandlePointingDeviceUpEvent] delegate - space %@ and point %f,%f", space, point.x, point.y);
    return YES;
}

-(CGPoint)plotSpace:(CPTPlotSpace *)space willDisplaceBy:(CGPoint)proposedDisplacementVector
{
    NSLog(@"[GraphViewController willDisplaceBy] delegate");
    return proposedDisplacementVector;
}

-(CPTPlotRange *)plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate
{
    NSLog(@"[GraphViewController willChangePlotRangeTo] delegate %@", newRange);
    return newRange;
}

-(void)plotSpace:(CPTPlotSpace *)space didChangePlotRangeForCoordinate:(CPTCoordinate)coordinate
{
    NSLog(@"[GraphViewController didChangePlotRangeForCoordinate] delegate %@", [space identifier]);    
}

#pragma mark CPTScatterPlotDelegate methods

-(void)scatterPlot:(CPTScatterPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)index
{
    NSLog(@"[GraphViewController plotSymbolWasSelectedAtRecordIndex] delegate %@ at %lu", plot, index);
    
    //
    // The graph view starts with the oldest reading. Let's reverse the index
    // to select on the Reading View
    [[NSNotificationCenter defaultCenter] postNotificationName:GraphDataPointWasSelectedNotification object:[NSNumber numberWithUnsignedInteger:[self.dataSourceSortedReadings count]-index]];
}

#pragma mark SWDatePickerProtocol
- (void)dateRangeSelectionChanged:(SWDatePicker*)control selectedStartDate:(NSDate*)start selectedEndDate:(NSDate*)end
{
    //
    // The user has changed the date range on the date Picker
    NSLog(@"[GraphViewController dateRangeSelectionChanged] delegate");
}

@end
