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
#import "UserFilter.h"

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
@property (nonatomic, readwrite, retain) IBOutlet NSTextField *averageSystolicPressure;
@property (nonatomic, readwrite, retain) IBOutlet NSTextField *averageDiastolicPressure;
@property (nonatomic, readwrite, retain) IBOutlet NSTextField *averageHeartRate;
@property (nonatomic, readwrite, assign) UserFilter userFilter;

- (void)dataSyncOperationDidEnd:(NSNotification*)notif;
- (void)dataSyncOperationDataAvailable:(NSNotification*)notif;
- (void)userFilterDidChange:(NSNotification*)notif;
- (void)updateSortedReadings;
- (void)recalculateGraphAxis;
- (void)recalculateDatePickerRange;
- (NSDate*)firstDayOfMonthForDate:(NSDate*)aDate;
- (NSDate*)lastDayOfMonthForDate:(NSDate*)aDate;
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
@synthesize dateRangeLabel = mDateRangeLabel;
@synthesize averageSystolicPressure = mAverageSystolicPressure;
@synthesize averageDiastolicPressure = mAverageDiastolicPressure;
@synthesize averageHeartRate = mAverageHeartRate;
@synthesize userFilter = mUserFilter;

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(userFilterDidChange:) 
                                                     name:UserFilterDidChangeNotification 
                                                   object:nil];
        
        
        // Create Main Graph 
        mGraph = [[CPTXYGraph alloc] initWithFrame:self.view.bounds];
        mHostView.hostedGraph = mGraph;
        
        mGraph.plotAreaFrame.borderLineStyle = nil;
        mGraph.defaultPlotSpace.delegate = (id)self;
        mGraph.plotAreaFrame.paddingTop = 30.0;
        mGraph.plotAreaFrame.paddingLeft = 40.0;
        mGraph.plotAreaFrame.paddingBottom = 60.0;
        mGraph.plotAreaFrame.paddingRight = 20.0;
        
        // Main Graph Title
        CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
        textStyle.color = [CPTColor darkGrayColor];
        textStyle.fontSize = 12.0f;
        textStyle.fontName = [[NSFont messageFontOfSize:12.0f] fontName];
        mGraph.title = @"";
        mGraph.titleTextStyle = textStyle;
        mGraph.titleDisplacement = CGPointMake(0.0f, -20.0f);
        
        // Add Pulse line style
        CGFloat values[4]	= { 111.0/255.0, 206.0/255.0, 145.0/255.0, 0.5f };
        CGColorRef colorRef = CGColorCreate([CPTColorSpace genericRGBSpace].cgColorSpace, values);
        CPTColor *pulseColor = [[[CPTColor alloc] initWithCGColor:colorRef] autorelease];
        CGColorRelease(colorRef);
        
        CPTMutableLineStyle *pulseLineStyle = [CPTMutableLineStyle lineStyle];
        pulseLineStyle.lineWidth = 1.0f;
        pulseLineStyle.lineColor = pulseColor;
        
        // Add Pressure line style
        CGFloat values2[4]	= { 39.0/255.0, 193.0/255.0, 219.0/255.0, 0.5f };
        CGColorRef colorRef2 = CGColorCreate([CPTColorSpace genericRGBSpace].cgColorSpace, values2);
        CPTColor *pressureColor = [[[CPTColor alloc] initWithCGColor:colorRef2] autorelease];
        CGColorRelease(colorRef2);
        
        CPTMutableLineStyle *bloodPressureLineStyle = [CPTMutableLineStyle lineStyle];
        bloodPressureLineStyle.lineWidth = 1.0f;
        bloodPressureLineStyle.lineColor = pressureColor;
        
        // Main Graph Axes
        CPTXYAxisSet *axisSet = (CPTXYAxisSet *)mGraph.axisSet;
        CPTXYAxis *x = axisSet.xAxis;
        
        x.axisLineCapMax = [[[CPTLineCap alloc] init] autorelease];
        x.axisLineCapMax.lineCapType = CPTLineCapTypeOpenArrow;
        x.labelTextStyle = textStyle;
        
        CPTXYAxis *y = axisSet.yAxis;
        y.majorIntervalLength = CPTDecimalFromString(@"10");
        y.minorTicksPerInterval = 0;
        y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0.0f);
        y.labelTextStyle = textStyle; 
        
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
        mSystolicGraph.plotAreaFrame.paddingBottom = 30.0;
        mSystolicGraph.plotAreaFrame.paddingRight = 20.0;
        
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
        x.labelTextStyle = textStyle;

        y = axisSet.yAxis;
        y.majorIntervalLength = CPTDecimalFromInt(10);
        y.minorTicksPerInterval = 0;
        y.orthogonalCoordinateDecimal = CPTDecimalFromInt(0);
        y.labelFormatter = numberFormatter;
        y.labelTextStyle = textStyle;

        mSystolicBarPlot = [[CPTBarPlot alloc] initWithFrame:mSystolicGraph.bounds];
        mSystolicBarPlot.identifier = @"Systolic Bar Plot";
        mSystolicBarPlot.opacity = 0.8f;
        mSystolicBarPlot.dataSource = self;  
        mSystolicBarPlot.delegate = self;
        mSystolicBarPlot.barOffset = CPTDecimalFromFloat(0.5);
        mSystolicBarPlot.barCornerRadius = 6.0f;
        mSystolicBarPlot.barWidth = CPTDecimalFromFloat(0.80f);
        mSystolicBarPlot.barWidthsAreInViewCoordinates = NO;
        mSystolicBarPlot.lineStyle = bloodPressureLineStyle;
        mSystolicBarPlot.labelTextStyle = textStyle;
        mSystolicBarPlot.labelOffset = -0.01f;
        mSystolicBarPlot.fill = [[[CPTFill alloc] initWithColor:pressureColor] autorelease];
        
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
        mDiastolicGraph.plotAreaFrame.paddingBottom = 30.0;
        mDiastolicGraph.plotAreaFrame.paddingRight = 20.0;
        
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
        x.labelTextStyle = textStyle;
        
        y = axisSet.yAxis;
        y.majorIntervalLength = CPTDecimalFromInt(10);
        y.minorTicksPerInterval = 0;
        y.orthogonalCoordinateDecimal = CPTDecimalFromInt(0);
        y.labelFormatter = numberFormatter;
        y.labelTextStyle = textStyle;
        
        mDiastolicBarPlot = [[CPTBarPlot alloc] initWithFrame:mDiastolicGraph.bounds];
        mDiastolicBarPlot.identifier = @"Diastolic Bar Plot";
        mDiastolicBarPlot.opacity = 0.8f;
        mDiastolicBarPlot.dataSource = self;  
        mDiastolicBarPlot.delegate = self;
        mDiastolicBarPlot.barOffset = CPTDecimalFromFloat(0.5);
        mDiastolicBarPlot.barCornerRadius = 6.0f;
        mDiastolicBarPlot.barWidth = CPTDecimalFromFloat(0.80f);
        mDiastolicBarPlot.lineStyle = bloodPressureLineStyle;
        mDiastolicBarPlot.labelTextStyle = textStyle;
        mDiastolicBarPlot.labelOffset = -0.01f;
        mDiastolicBarPlot.fill = [[[CPTFill alloc] initWithColor:pressureColor] autorelease];

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

- (NSDate*)firstDayOfMonthForDate:(NSDate*)aDate    
{
    NSDate *date = nil;
    
    NSCalendar *gregorian = [[NSCalendar alloc] 
                             initWithCalendarIdentifier:NSGregorianCalendar]; 
    
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit; 
    
    NSDateComponents *components = [gregorian components:unitFlags 
                                                fromDate:aDate]; 
    
    [components setDay:1];
    date = [gregorian dateFromComponents:components];
    
    return date;
}

- (NSDate*)lastDayOfMonthForDate:(NSDate*)aDate 
{
    NSDate *date = nil;
    
    NSCalendar *gregorian = [[NSCalendar alloc] 
                             initWithCalendarIdentifier:NSGregorianCalendar]; 
    
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit; 
    
    NSDateComponents *components = [gregorian components:unitFlags 
                                                fromDate:aDate]; 
    
    //
    // Figure out the date from the components
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

- (void)updateSortedReadings
{
    // Table Reload
//    NSLog(@"[GraphViewController updateSortedReadings]");
    
    //
    // Let's take the data and sort it by date. There is no guarantee that the datasource.readings are
    // in any order
    //
    if ([self.dataSource.omronDataRecords count] > 0)
    {
        self.dataSourceSortedReadings = [self.dataSource.omronDataRecords sortedArrayUsingComparator:^(id a, id b) {
            NSDate *first = [(OmronDataRecord*)a readingDate];
            NSDate *second = [(OmronDataRecord*)b readingDate];
            return [first compare:second];
        }];
    }
    

}

- (void)recalculateFrequencyDistributionHistogram
{
    if ([self.dataSourceSortedReadings count] > 0)
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
        float highestValue = 0;
        CPTXYPlotSpace *barPlotSpace = nil;
        NSInteger diastolicPressureSum = 0;
        
        //
        // SYSTOLIC
        //
        NSArray *readingsSortedBySystolicPressure = [self.dataSourceSortedReadings sortedArrayUsingComparator:^(id a, id b) {
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
        
        NSMutableArray *systolicFrequencyDistribution = [[NSMutableArray alloc] initWithCapacity:K];
        
        //
        // Initialize the frequency distribution values
        for (int i=0; i<K; i++) 
        {
            [systolicFrequencyDistribution insertObject:[NSNumber numberWithInt:0] atIndex:i];
        }
        
        //
        // Put each value in a slot
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
        }
        
        //
        // Use Key Path builtin to show the average of the dataset
        NSNumber *sysAverage = [self.dataSourceSortedReadings valueForKeyPath:@"@avg.systolicPressure"];
        self.averageSystolicPressure.stringValue = [NSString stringWithFormat:@"%ld", [sysAverage intValue]];
        
        //
        // calculate the percentage of values in each range
        highestValue = 0;
        for (int index=0; index<K; index++) 
        {
            NSNumber *value = [systolicFrequencyDistribution objectAtIndex:index];
//            NSLog(@"Systolic freq is %i", [value intValue]);
            float percentage =  [value floatValue] / (int)[readingsSortedBySystolicPressure count];
            percentage *= 100;
            [systolicFrequencyDistribution replaceObjectAtIndex:index withObject:[NSNumber numberWithFloat:percentage]];

            if (percentage > highestValue)
            {
                highestValue = percentage;
            }
        }
        
        self.systolicFrequencyDistribution = systolicFrequencyDistribution;
        
        barPlotSpace = (CPTXYPlotSpace*)self.systolicGraph.defaultPlotSpace;
        barPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromFloat(highestValue + 5.0f)];
        
        //
        // Put custom labels on the Major Ticks. This will show the range
        NSMutableArray *customSystolicLabels = [NSMutableArray arrayWithCapacity:K];
        NSMutableArray *customSystolicMajorTickLocations = [NSMutableArray arrayWithCapacity:K];
        
        CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.systolicGraph.axisSet;
        CPTXYAxis *x = axisSet.xAxis;
        
        for (unsigned int i=0; i <= K; i++)
        {
            CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%i", S+i*W] textStyle:x.labelTextStyle];
            NSNumber* numMajorTickLocation = [NSNumber numberWithInt:i];
            newLabel.tickLocation = [numMajorTickLocation decimalValue];
            [customSystolicLabels addObject:newLabel];
            [customSystolicMajorTickLocations addObject:numMajorTickLocation];
            [newLabel release];
        }
        
        x.axisLabels = [NSSet setWithArray:customSystolicLabels];
        x.majorTickLocations = [NSSet setWithArray:customSystolicMajorTickLocations];

        [self.systolicGraph reloadData];
       
        //
        // DIASTOLIC
        //
        NSArray *readingsSortedByDiastolicPressure = [self.dataSourceSortedReadings sortedArrayUsingComparator:^(id a, id b) {
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
        
        //NSLog(@"recalculateFrequencyDistributionHistogram - L is %ld, S is %ld W is %ld", L,S,W);
        NSMutableArray *diastolicFrequencyDistribution = [[NSMutableArray alloc] initWithCapacity:K];
        
        //
        // Initialize the frequency distribution values
        for (int i=0; i<K; i++) 
        {
            [diastolicFrequencyDistribution insertObject:[NSNumber numberWithInt:0] atIndex:i];
        }
        
        //
        // Put each value in a slot
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
            
            //
            // While we are looping over the Diastolic Pressures, let's add them all up to take an average
            diastolicPressureSum += diastolicPressure;
        }
        
        self.averageDiastolicPressure.stringValue = [NSString stringWithFormat:@"%ld", diastolicPressureSum / readingsSortedByDiastolicPressure.count];

        //
        // calculate the percentage of values in each range
        highestValue = 0;
        for (int index=0; index<K; index++) 
        {
            NSNumber *value = [diastolicFrequencyDistribution objectAtIndex:index];
//            NSLog(@"Diastolic freq is %i", [value intValue]);
            float percentage =  [value floatValue] / (int)[readingsSortedBySystolicPressure count];
            percentage *= 100;
            [diastolicFrequencyDistribution replaceObjectAtIndex:index withObject:[NSNumber numberWithFloat:percentage]];
            
            if (percentage > highestValue)
            {
                highestValue = percentage;
            }
        }        
        self.diastolicFrequencyDistribution = diastolicFrequencyDistribution;
        
        barPlotSpace = (CPTXYPlotSpace*)self.diastolicGraph.defaultPlotSpace;
        barPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromFloat(highestValue + 5.0f)];
        
        //
        // Put custom labels on the Major Ticks. This will show the range
        NSMutableArray *customDiastolicLabels = [NSMutableArray arrayWithCapacity:K];
        NSMutableArray *customDiastolicMajorTickLocations = [NSMutableArray arrayWithCapacity:K];
        
        CPTXYAxisSet *diastolicAxisSet = (CPTXYAxisSet *)self.diastolicGraph.axisSet;
        x = diastolicAxisSet.xAxis;
        
        for (unsigned int i=0; i <= K; i++)
        {
            CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%i", S+i*W] textStyle:x.labelTextStyle];
            NSNumber* numMajorTickLocation = [NSNumber numberWithInt:i];
            newLabel.tickLocation = [numMajorTickLocation decimalValue];
            [customDiastolicLabels addObject:newLabel];
            [customDiastolicMajorTickLocations addObject:numMajorTickLocation];
            [newLabel release];
        }
        
        x.axisLabels = [NSSet setWithArray:customDiastolicLabels];
        x.majorTickLocations = [NSSet setWithArray:customDiastolicMajorTickLocations];
        
        [self.diastolicGraph reloadData];
        
        //
        // Calculate the Average Heartrate
        NSUInteger summedHeartRate = 0;
        for (OmronDataRecord *record in [self dataSourceSortedReadings])
        {
            summedHeartRate += [record heartRate];
        }
        self.averageHeartRate.stringValue = [NSString stringWithFormat:@"%ld", summedHeartRate / readingsSortedBySystolicPressure.count];
    }
    
}

- (void)recalculateGraphAxis
{
    //
    // We have the list ordered by date, let's get the date of the first
    // record and set the axis accordingly for the Pressure/Pulse plots
    //
    if ([self.dataSourceSortedReadings count] > 0)
    {
        OmronDataRecord *record = [self.dataSourceSortedReadings objectAtIndex:0];
        
        //
        // We want to set the timeline reference date to the First Day of the Month of the first reading
        //
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]; 
        NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit; 
        NSDateComponents *components = [gregorian components:unitFlags fromDate:[record readingDate]]; 
        [components setDay:1];
        self.referenceDate = [gregorian dateFromComponents:components];
        
        
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        dateFormatter.dateStyle = kCFDateFormatterShortStyle;
        
        CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
        CPTXYAxis *x = axisSet.xAxis;
        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
        
        NSDate *ending = [[self.dataSourceSortedReadings lastObject] readingDate];
        plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(0) length:CPTDecimalFromInteger([[self lastDayOfMonthForDate:ending] timeIntervalSinceDate:self.referenceDate])];
        
        NSLog(@"recalculateGraphAxis: plotSpace.xRange.location is %f lotSpace.xRange.length is %f",plotSpace.xRange.locationDouble , plotSpace.xRange.lengthDouble);
        
        //
        // For the Y range, we want the lowest Diastolic or lowest Heartrate and the Highest Systolic
        NSArray *readingsSortedBySystolicPressure = [self.dataSourceSortedReadings sortedArrayUsingComparator:^(id a, id b) {
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

        NSArray *readingsSortedByDiastolicPressure = [self.dataSourceSortedReadings sortedArrayUsingComparator:^(id a, id b) {
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
        
        NSArray *readingsSortedByHeartrate = [self.dataSourceSortedReadings sortedArrayUsingComparator:^(id a, id b) {
            NSInteger first = [(OmronDataRecord*)a heartRate];
            NSInteger second = [(OmronDataRecord*)b heartRate];
            if ( first < second ) {
                return (NSComparisonResult)NSOrderedAscending;
            } else if ( first > second ) {
                return (NSComparisonResult)NSOrderedDescending;
            } else {
                return (NSComparisonResult)NSOrderedSame;
            }
        }];
        
        NSInteger lowestDiastolic = [[readingsSortedByDiastolicPressure objectAtIndex:0] diastolicPressure];
        NSInteger lowestHeartrate = [[readingsSortedByHeartrate objectAtIndex:0] heartRate];
        NSInteger lowestValue = lowestDiastolic<lowestHeartrate ? lowestDiastolic : lowestHeartrate;
        NSInteger highestSystolic = [[readingsSortedBySystolicPressure lastObject] systolicPressure];
        int roundedLowValue = ((((int)lowestValue - 10) / 10) * 10);

        plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(roundedLowValue) length:CPTDecimalFromFloat(highestSystolic - roundedLowValue + 20.0f)];
        
        //
        // Layout the Axis labels
        //
        x.orthogonalCoordinateDecimal = CPTDecimalFromInteger(roundedLowValue);
        x.labelingPolicy = CPTAxisLabelingPolicyNone;
        
        axisSet.yAxis.orthogonalCoordinateDecimal = CPTDecimalFromInteger(0);
        
        NSMutableArray *customLabels = [NSMutableArray arrayWithCapacity:24];
        NSMutableArray *customMajorTickLocations = [NSMutableArray arrayWithCapacity:24];
        NSUInteger oneDay = 3600*24;
        
//        NSUInteger daysInRange = [[NSDecimalNumber decimalNumberWithDecimal:plotSpace.xRange.length] intValue] / oneDay;
//        NSLog(@"[GraphViewController didChangePlotRangeForCoordinate] Will show months %ld", daysInRange); 
        
        NSDate* currentDate = [[self.dataSourceSortedReadings objectAtIndex:0] readingDate];
        NSDate* lastDate = [[self.dataSourceSortedReadings lastObject] readingDate];
        components = [[NSDateComponents alloc] init];
        [components setMonth:1];

        while (NSOrderedAscending == [currentDate compare:lastDate])
        {
            NSTimeInterval interval = [currentDate timeIntervalSinceDate:self.referenceDate];
            NSNumber* numMajorTickLocation = [NSNumber numberWithDouble:interval];
            NSNumber* numMinorTickLocation = [NSNumber numberWithDouble:interval+14*oneDay];
            NSDateComponents *monthComponents = [gregorian components:unitFlags fromDate:currentDate];
            NSString *monthName = [[dateFormatter shortMonthSymbols] objectAtIndex:([monthComponents month]-1)];
            CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithText:monthName textStyle:x.labelTextStyle];
            newLabel.tickLocation = [numMinorTickLocation decimalValue];
            newLabel.offset = x.labelOffset + x.majorTickLength;

            currentDate = [gregorian dateByAddingComponents:components toDate:currentDate options:0];

            [customLabels addObject:newLabel];
            [customMajorTickLocations addObject:numMajorTickLocation];
            [newLabel release];
        }

        // add a last major tick to close the range
        [customMajorTickLocations addObject:[NSNumber numberWithDouble:[[self lastDayOfMonthForDate:currentDate] timeIntervalSinceDate:self.referenceDate]]];

       
        x.axisLabels = [NSSet setWithArray:customLabels];
        x.majorTickLocations = [NSSet setWithArray:customMajorTickLocations];

    }

}

- (void)recalculateDatePickerRange
{
//    NSLog(@"recalculateDatePickerRange [self.dataSourceSortedReadings objectAtIndex:0]=%@, [[self.dataSourceSortedReadings objectAtIndex:0] readingDate]=%@", [self.dataSourceSortedReadings objectAtIndex:0], [[self.dataSourceSortedReadings objectAtIndex:0] readingDate]);
    
    if ([self.dataSourceSortedReadings objectAtIndex:0])
    {
        self.datePicker.rangeStartDate = [self firstDayOfMonthForDate:[[self.dataSourceSortedReadings objectAtIndex:0] readingDate]];
        self.datePicker.rangeEndDate = [self lastDayOfMonthForDate:[NSDate date]];
        
//        NSLog(@"recalculateDatePickerRange rangeStartDate=%@, rangeEndDate=%@", self.datePicker.rangeStartDate, self.datePicker.rangeEndDate);
        
        if (!self.datePicker.displayedStartDate)
        {
            self.datePicker.displayedStartDate = self.datePicker.rangeStartDate;
            self.datePicker.selectedStartDate = self.datePicker.rangeStartDate;
        }
        
        if (!self.datePicker.displayedEndDate)
        {
            self.datePicker.displayedEndDate = self.datePicker.rangeEndDate;
            self.datePicker.selectedEndDate = self.datePicker.rangeEndDate;
        }
        
        [self.datePicker setNeedsDisplay];
    }
    else
    {
        NSLog(@"recalculateDatePickerRange - No data, not updating the Date Picker");
    }
}

#pragma mark NSViewController methods

- (void)viewWillAppear
{
    [self.backdropView setImage:[NSImage imageNamed:@"backdrop.png"]];
    [self.graph reloadData];
    [self.systolicGraph reloadData];
    [self.diastolicGraph reloadData];
}

#pragma mark NSResponder events

- (void)swipeWithEvent:(NSEvent *)event 
{
    //NSLog(@"Swipe event detected!");
}
- (void)beginGestureWithEvent:(NSEvent *)event 
{
    //NSLog(@"beginGestureWithEvent event detected!");
}
- (void)endGestureWithEvent:(NSEvent *)event 
{
    //NSLog(@"endGestureWithEvent event detected!");
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
    
    if (plot == self.systolicBarPlot)
    {
        switch (fieldEnum) {
            case CPTBarPlotFieldBarLocation:
                num = (NSDecimalNumber *)[NSDecimalNumber numberWithInteger:index];
                //NSLog(@"systolicBarPlot CPTBarPlotFieldBarLocation: %d", [num intValue]);
                break;
            case CPTBarPlotFieldBarTip:
                num = [self.systolicFrequencyDistribution objectAtIndex:index];
                //NSLog(@"systolicBarPlot CPTBarPlotFieldBarTip: %d", [num intValue]);
                break;
            case CPTBarPlotFieldBarBase:
                num = (NSDecimalNumber *)[NSDecimalNumber numberWithInteger:0];;
                //NSLog(@"systolicBarPlot CPTBarPlotFieldBarBase: %d", [num intValue]);
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
                //NSLog(@"diastolicBarPlot CPTBarPlotFieldBarLocation: %d", [num intValue]);
                break;
            case CPTBarPlotFieldBarTip:
                num = [self.diastolicFrequencyDistribution objectAtIndex:index];
                //NSLog(@"diastolicBarPlot CPTBarPlotFieldBarTip: %d", [num intValue]);
                break;
            case CPTBarPlotFieldBarBase:
                num = (NSDecimalNumber *)[NSDecimalNumber numberWithInteger:0];;
                //NSLog(@"diastolicBarPlot CPTBarPlotFieldBarBase: %d", [num intValue]);
                break;
            default:
                NSLog(@"diastolicBarPlot unknown field enum %lu", fieldEnum);
                break;
        }
        
    }
    else
    if (plot == self.pulseLinePlot)
    {
        OmronDataRecord *record = [self.dataSourceSortedReadings objectAtIndex:index];
        NSDate *readingDate = [record readingDate];
        NSTimeInterval interval = [readingDate timeIntervalSinceDate:self.referenceDate];

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
        OmronDataRecord *record = [self.dataSourceSortedReadings objectAtIndex:index];
        NSDate *readingDate = [record readingDate];
        NSTimeInterval interval = [readingDate timeIntervalSinceDate:self.referenceDate];

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

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index
{
    CPTTextLayer *label = nil; 
    NSString *labelText = nil;
    NSDecimalNumber *num = [NSDecimalNumber zero];
    
    if (plot == self.systolicBarPlot)
    {
        num = [self.systolicFrequencyDistribution objectAtIndex:index];
        labelText = [NSString stringWithFormat:@"%lu%%", [num intValue]];
        label = [[CPTTextLayer alloc] initWithText:labelText];     
        if ([num intValue] > 5)
        {
            //
            // We only want to print a label on the inside if the Bar is greater than 5%, otherwise, it will be clipped
            plot.labelOffset = -0.01f;
        }
        else
        {
            plot.labelOffset = 0.01f;
        }
    }
    else if (plot == self.diastolicBarPlot)
    {
        num = [self.diastolicFrequencyDistribution objectAtIndex:index];
        labelText = [NSString stringWithFormat:@"%lu%%", [num intValue]];
        label = [[CPTTextLayer alloc] initWithText:labelText]; 
        if ([num intValue] > 5)
        {
            //
            // We only want to print a label on the inside if the Bar is greater than 5%, otherwise, it will be clipped
            plot.labelOffset = -0.01f;
        }
        else
        {
            plot.labelOffset = 0.01f;
        }
    }
    
    return [label autorelease];
}

#pragma mark NSNotification Observers

- (void)dataSyncOperationDidEnd:(NSNotification*)notif
{
    //
    // These need to be in this order. The recalculateFrequencyDistributionHistogram and recalculateGraphAxis
    // depend on the recalculateDatePickerRange
    //
    [self updateSortedReadings];
    [self recalculateDatePickerRange];
    
    NSPredicate *predicate = [NSPredicate
                              predicateWithFormat:@"(readingDate >= %@) AND (readingDate <= %@)",
                              self.datePicker.displayedStartDate, self.datePicker.displayedEndDate];
    self.dataSourceSortedReadings = [self.dataSourceSortedReadings filteredArrayUsingPredicate:predicate];

    NSPredicate *userPredicate = nil;
    if ((self.userFilter == userAOnly) || (self.userFilter == userBOnly))
    {
        //
        // Take a shortcut with self.userFilter by casting it as an (int) to get 0 for UserA and 1 for UserB
        //
        userPredicate = [NSPredicate predicateWithFormat:@"dataBank == %i", (int)self.userFilter];
        self.dataSourceSortedReadings = [self.dataSourceSortedReadings filteredArrayUsingPredicate:userPredicate];
    }
    else
    {
        // Otherwise, we do not filter by the User
    }
    
    //
    // Remove anything that the user wants taken out
    //
    NSPredicate *excludePredicate = [NSPredicate predicateWithFormat:@"excludeFromGraph == TRUE"];  
    self.dataSourceSortedReadings = [self.dataSourceSortedReadings filteredArrayUsingPredicate:excludePredicate];
    
    [self recalculateFrequencyDistributionHistogram];
    [self recalculateGraphAxis];
    
    [self.graph reloadData];
}

- (void)dataSyncOperationDataAvailable:(NSNotification*)notif
{
    [self updateSortedReadings];
    [self recalculateDatePickerRange];

    NSPredicate *predicate = [NSPredicate
                              predicateWithFormat:@"(readingDate >= %@) AND (readingDate <= %@)",
                              self.datePicker.displayedStartDate, self.datePicker.displayedEndDate];
    self.dataSourceSortedReadings = [self.dataSourceSortedReadings filteredArrayUsingPredicate:predicate];
    
    NSPredicate *userPredicate = nil;
    if ((self.userFilter == userAOnly) || (self.userFilter == userBOnly))
    {
        //
        // Take a shortcut with self.userFilter by casting it as an (int) to get 0 for UserA and 1 for UserB
        //
        userPredicate = [NSPredicate predicateWithFormat:@"dataBank == %i", (int)self.userFilter];
        self.dataSourceSortedReadings = [self.dataSourceSortedReadings filteredArrayUsingPredicate:userPredicate];
    }
    else
    {
        // Otherwise, we do not filter by the User
    }

    //
    // Remove anything that the user wants taken out
    //
    NSPredicate *excludePredicate = [NSPredicate predicateWithFormat:@"excludeFromGraph == TRUE"];  
    self.dataSourceSortedReadings = [self.dataSourceSortedReadings filteredArrayUsingPredicate:excludePredicate];
    
    [self recalculateFrequencyDistributionHistogram];
    [self recalculateGraphAxis];
    
    [self.graph reloadData];
}

- (void)userFilterDidChange:(NSNotification*)notif
{
    //
    // Receive the new filter value
    self.userFilter = (UserFilter)[[notif object] intValue];
//    NSLog(@"Changing the userFilter to %i", self.userFilter);
    
    //
    // Reset the array to the original, unsorted, unfiltered dataset
    //
    self.dataSourceSortedReadings = self.dataSource.omronDataRecords;
    
    //
    // Reset the date picker display to the full available range
    self.datePicker.displayedStartDate = self.datePicker.rangeStartDate;
    self.datePicker.displayedEndDate = self.datePicker.rangeEndDate;
    
    //
    // Remove all but the ones in our date range
    //
    NSPredicate *predicate = [NSPredicate
                              predicateWithFormat:@"(readingDate >= %@) AND (readingDate <= %@)",
                              self.datePicker.rangeStartDate, self.datePicker.rangeEndDate];
    self.dataSourceSortedReadings = [self.dataSourceSortedReadings filteredArrayUsingPredicate:predicate];
    
    //
    // Remove all but the ones for our user(s)
    //
    NSPredicate *userPredicate = nil;
    if ((self.userFilter == userAOnly) || (self.userFilter == userBOnly))
    {
        //
        // Take a shortcut with self.userFilter by casting it as an (int) to get 0 for UserA and 1 for UserB
        //
        userPredicate = [NSPredicate predicateWithFormat:@"dataBank == %i", (int)self.userFilter];
        self.dataSourceSortedReadings = [self.dataSourceSortedReadings filteredArrayUsingPredicate:userPredicate];
    }
    else
    {
        // Otherwise, we do not filter by the User
    }
    
    //
    // Remove anything that the user wants taken out
    //
    NSPredicate *excludePredicate = [NSPredicate predicateWithFormat:@"excludeFromGraph == TRUE"];  
    self.dataSourceSortedReadings = [self.dataSourceSortedReadings filteredArrayUsingPredicate:excludePredicate];
    
    //
    // Recalculate and redisplay
    //
    [self recalculateFrequencyDistributionHistogram];
    [self recalculateGraphAxis];
    
    [self.graph reloadData];

}

#pragma mark CPTPlotSpaceDelegate methods

-(BOOL)plotSpace:(CPTPlotSpace*)space shouldScaleBy:(CGFloat)interactionScale aboutPoint:(CGPoint)interactionPoint
{
//    NSLog(@"[GraphViewController shouldScaleBy] delegate");
    return YES;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDownEvent:(id)event atPoint:(CGPoint)point 
{
//    NSLog(@"[GraphViewController shouldHandlePointingDeviceDownEvent] delegate");
    return YES;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDraggedEvent:(id)event atPoint:(CGPoint)point
{
//    NSLog(@"[GraphViewController shouldHandlePointingDeviceDraggedEvent] delegate");
    return YES;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceCancelledEvent:(id)event
{
//    NSLog(@"[GraphViewController shouldHandlePointingDeviceCancelledEvent] delegate");
   return YES;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceUpEvent:(id)event atPoint:(CGPoint)point
{
//    NSLog(@"[GraphViewController shouldHandlePointingDeviceUpEvent] delegate - space %@ and point %f,%f", space, point.x, point.y);
    return YES;
}

-(CGPoint)plotSpace:(CPTPlotSpace *)space willDisplaceBy:(CGPoint)proposedDisplacementVector
{
//    NSLog(@"[GraphViewController willDisplaceBy] delegate");
    return proposedDisplacementVector;
}

-(CPTPlotRange *)plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate
{
//    NSLog(@"[GraphViewController willChangePlotRangeTo] delegate %@", newRange);
    return newRange;
}

-(void)plotSpace:(CPTPlotSpace *)space didChangePlotRangeForCoordinate:(CPTCoordinate)coordinate
{
//    NSLog(@"[GraphViewController didChangePlotRangeForCoordinate] delegate %@, coordinate=%i", space, coordinate); 
}

#pragma mark CPTScatterPlotDelegate methods

-(void)scatterPlot:(CPTScatterPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)index
{
    NSLog(@"[GraphViewController plotSymbolWasSelectedAtRecordIndex] delegate %@ at %lu which should be reading %@", plot, index, [self.dataSourceSortedReadings objectAtIndex:index]);
    
    //
    // The graph view starts with the oldest reading. Let's reverse the index
    // to select on the Reading View
    [[NSNotificationCenter defaultCenter] postNotificationName:GraphDataPointWasSelectedNotification object:[self.dataSourceSortedReadings objectAtIndex:index]];
}

#pragma mark SWDatePickerProtocol
- (void)dateRangeSelectionChanged:(SWDatePicker*)control selectedStartDate:(NSDate*)start selectedEndDate:(NSDate*)end
{
    //
    // The user has changed the date range on the date Picker
    NSLog(@"[GraphViewController dateRangeSelectionChanged] delegate start:%@ end:%@", start, end);
    
    //
    // UpdateSortedReadings will go back to the original datasource and discard
    //
    // These need to be in this order. The recalculateFrequencyDistributionHistogram and recalculateGraphAxis
    // depend on the recalculateDatePickerRange
    //
    self.dataSourceSortedReadings = self.dataSource.omronDataRecords;

    self.datePicker.selectedStartDate = start;
    self.datePicker.selectedEndDate = end;

    NSPredicate *predicate = [NSPredicate
                              predicateWithFormat:@"(readingDate >= %@) AND (readingDate <= %@)",
                              start, end];
    self.dataSourceSortedReadings = [self.dataSourceSortedReadings filteredArrayUsingPredicate:predicate];
    

    NSPredicate *userPredicate = nil;
    if ((self.userFilter == userAOnly) || (self.userFilter == userBOnly))
    {
        //
        // Take a shortcut with self.userFilter by casting it as an (int) to get 0 for UserA and 1 for UserB
        //
        userPredicate = [NSPredicate predicateWithFormat:@"dataBank == %i", (int)self.userFilter];
        self.dataSourceSortedReadings = [self.dataSourceSortedReadings filteredArrayUsingPredicate:userPredicate];
    }
    else
    {
        // Otherwise, we do not filter by the User
    }
    
    [self recalculateFrequencyDistributionHistogram];
    [self recalculateGraphAxis];
    
    [self.graph reloadData];
}

@end
