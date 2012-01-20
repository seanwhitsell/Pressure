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

#pragma mark Private Interface

@interface GraphViewController()

@property (nonatomic, readwrite, retain) OmronDataSource *dataSource;
@property (nonatomic, readwrite, retain) NSArray *dataSourceSortedReadings;
@property (nonatomic, readwrite, retain) NSArray *plotData;
@property (nonatomic, readwrite, retain) CPTXYGraph *graph;
@property (nonatomic, readwrite, retain) CPTLineStyle *barLineStyle;
@property (nonatomic, readwrite, retain) CPTFill *areaFill;
@property (nonatomic, readwrite, retain) CPTScatterPlot *pulseLinePlot;
@property (nonatomic, readwrite, retain) CPTTradingRangePlot *bloodPressureLinePlot;
@property (nonatomic, readwrite, retain) NSDate *referenceDate;

- (void)dataSyncOperationDidEnd:(NSNotification*)notif;
- (void)dataSyncOperationDataAvailable:(NSNotification*)notif;

@end

@implementation GraphViewController

@synthesize dataSource = mDataSource;
@synthesize hostView = mHostView;
@synthesize dataSourceSortedReadings = mDataSourceSortedReadings;
@synthesize graph = mGraph;
@synthesize plotData = mPlotData;
@synthesize barLineStyle = mBarLineStyle;
@synthesize areaFill = mAreaFill;
@synthesize pulseLinePlot = mPulseLinePlot;
@synthesize bloodPressureLinePlot = mBloodPressureLinePlot;
@synthesize referenceDate = mReferenceDate;
@synthesize backdropView = mBackdropView;

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
        
        
        // Create graph 
        mGraph = [[CPTXYGraph alloc] initWithFrame:self.view.bounds];
        mHostView.hostedGraph = mGraph;
        
        CGFloat values[4]	= { 111.0/255.0, 206.0/255.0, 145.0/255.0, 1.0 };
        CGColorRef colorRef = CGColorCreate([CPTColorSpace genericRGBSpace].cgColorSpace, values);
        CPTColor *color		= [[CPTColor alloc] initWithCGColor:colorRef];
        CGColorRelease(colorRef);
        
        mGraph.plotAreaFrame.borderLineStyle = nil;
        mGraph.defaultPlotSpace.delegate = (id)self;
        
        // Title
        CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
        textStyle.color = [CPTColor darkGrayColor];
        textStyle.fontSize = 18.0f;
        textStyle.fontName = @"Helvetica";
        mGraph.title = @"";
        mGraph.titleTextStyle = textStyle;
        mGraph.titleDisplacement = CGPointMake(0.0f, -20.0f);
        mGraph.plotAreaFrame.paddingTop = 30.0;
        mGraph.plotAreaFrame.paddingLeft = 40.0;
        mGraph.plotAreaFrame.paddingBottom = 60.0;
        mGraph.plotAreaFrame.paddingRight = 30.0;
        
        // Add line style
        CPTMutableLineStyle *pulseLineStyle = [CPTMutableLineStyle lineStyle];
        pulseLineStyle.lineWidth = 3.0f;
        pulseLineStyle.lineColor = color;
        
        // Add line style
        CPTMutableLineStyle *bloodPressureLineStyle = [CPTMutableLineStyle lineStyle];
        bloodPressureLineStyle.lineWidth = 1.0f;
        bloodPressureLineStyle.lineColor = [CPTColor redColor];
        
        // Axes
        CPTXYAxisSet *axisSet = (CPTXYAxisSet *)mGraph.axisSet;
        CPTXYAxis *x = axisSet.xAxis;
        
        x.majorIntervalLength = CPTDecimalFromFloat(oneDay * 10);
        x.minorTicksPerInterval = 10;
        x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"30");
        x.labelRotation = M_PI/4.0;
        x.axisLineCapMax = [[CPTLineCap alloc] init];
        x.axisLineCapMax.lineCapType = CPTLineCapTypeOpenArrow;
        
        CPTXYAxis *y = axisSet.yAxis;
        y.majorIntervalLength = CPTDecimalFromString(@"10");
        y.minorTicksPerInterval = 0;
        y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0.0f);
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [numberFormatter setGeneratesDecimalNumbers:NO];
        y.labelFormatter = numberFormatter;
        
        //
        // Create a plot that uses the data for the Heart Rate
        mPulseLinePlot = [[CPTScatterPlot alloc] initWithFrame:self.graph.bounds];
        mPulseLinePlot.identifier = @"Pulse Plot";
        mPulseLinePlot.dataLineStyle = pulseLineStyle;
        mPulseLinePlot.dataSource = self;    
        
        //
        // Create a plot that uses the data for the Blood Pressure (Systolic/Diastolic)
        mBloodPressureLinePlot = [[CPTTradingRangePlot alloc] initWithFrame:self.graph.bounds];
        mBloodPressureLinePlot.identifier = @"Blood Pressure";
        mBloodPressureLinePlot.lineStyle = bloodPressureLineStyle;
        mBloodPressureLinePlot.plotStyle = CPTTradingRangePlotStyleOHLC;
        mBloodPressureLinePlot.stickLength = 2.0f;
        mBloodPressureLinePlot.dataSource = self;    
        
        //
        // Add plots to the graph
        [mGraph addPlot:mPulseLinePlot];
        [mGraph addPlot:mBloodPressureLinePlot];
    }
	
	return self;
}

- (void)dealloc
{
    [super dealloc];
    
    [mPulseLinePlot release]; mPulseLinePlot = nil;
    [mGraph release]; mGraph = nil;
 
}

- (void)viewWillAppear
{
    [self.backdropView setImage:[NSImage imageNamed:@"backdrop.png"]];
    NSLog(@"[GraphViewController viewDidAppear]");
    [self.graph reloadData];

}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return 20; //[self.dataSource.readings count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSDecimalNumber *num = [NSDecimalNumber zero];
    OmronDataRecord *record = [self.dataSource.readings objectAtIndex:index];
    NSDate *readingDate = [record readingDate];
    NSTimeInterval interval = [readingDate timeIntervalSinceDate:self.referenceDate];
    
    NSLog(@"numberForPlot: %@", plot.identifier);
    
    if (record)
    {
        if (plot == self.pulseLinePlot)
        {
            switch (fieldEnum) 
            {
                case CPTScatterPlotFieldX:
                    num = (NSDecimalNumber *)[NSDecimalNumber numberWithInteger:interval];
                    NSLog(@"numberForPlot:CPTScatterPlotFieldX index %lu is %ld. fieldEnum is %lu", index, [num longValue], fieldEnum);
                    break;
                case CPTScatterPlotFieldY: 
                        num = (NSDecimalNumber *) [NSDecimalNumber numberWithLong:[record heartRate]];
                        NSLog(@"numberForPlot:CPTScatterPlotFieldY index %lu is %ld. fieldEnum is %lu", index, [num longValue], fieldEnum);
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
                    //num = [fData objectForKey:@"close"];
                    break;
                    
                case CPTTradingRangePlotFieldHigh:
                    num = (NSDecimalNumber *) [NSDecimalNumber numberWithLong:[record systolicPressure]];
                    break;
                    
                case CPTTradingRangePlotFieldLow:
                    num = (NSDecimalNumber *) [NSDecimalNumber numberWithLong:[record diastolicPressure]];
                    break;
                    
                case CPTTradingRangePlotFieldOpen:
                    //num = [fData objectForKey:@"open"];
                    break;                    
            }
           
        }
       
    }

    return num;
}

#pragma mark NSNotification Observers

- (void)dataSyncOperationDidEnd:(NSNotification*)notif
{
    // Table Reload
    NSLog(@"[GraphViewController dataSyncOperationDidEnd] Data Source isSampleData %s", [self.dataSource isSampleData] ? "yes":"no");
    
    self.dataSourceSortedReadings = [self.dataSource.readings sortedArrayUsingComparator:^(id a, id b) {
        NSDate *first = [(OmronDataRecord*)a readingDate];
        NSDate *second = [(OmronDataRecord*)b readingDate];
        return [first compare:second];
    }];
    
    [self.graph reloadData];
}

- (void)dataSyncOperationDataAvailable:(NSNotification*)notif
{
    NSLog(@"[GraphViewController dataSyncOperationDataAvailable] Data Source isSampleData %s", [self.dataSource isSampleData] ? "yes":"no");
    
    self.dataSourceSortedReadings = [self.dataSource.readings sortedArrayUsingComparator:^(id a, id b) {
        NSDate *first = [(OmronDataRecord*)a readingDate];
        NSDate *second = [(OmronDataRecord*)b readingDate];
        return [first compare:second];
    }];

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


@end
