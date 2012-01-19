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

@property (nonatomic, readwrite, retain) NSArray *dataSourceSortedReadings;
@property (nonatomic, readwrite, retain) CPTXYGraph *graph;
@property (nonatomic, readwrite, retain) NSArray *plotData;

- (void)dataSyncOperationDidEnd:(NSNotification*)notif;
- (void)dataSyncOperationDataAvailable:(NSNotification*)notif;

@end

@implementation GraphViewController

@synthesize dataSource = mDataSource;
@synthesize hostView = mHostView;
@synthesize dataSourceSortedReadings = mDataSourceSortedReadings;
@synthesize graph = mGraph;
@synthesize plotData = mPlotData;

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
        mGraph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:CGRectZero];

	}
	
	return self;
}

- (void)viewDidAppear
{
    NSDate *refDate = [NSDate dateWithNaturalLanguageString:@"12:00 Oct 29, 2009"];
    NSTimeInterval oneDay = 24 * 60 * 60;
    
    // Create graph from theme
    
	CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
	[self.graph applyTheme:theme];
	self.hostView.hostedGraph = self.graph;
    
    // Title
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
	textStyle.color = [CPTColor whiteColor];
    textStyle.fontSize = 18.0f;
    textStyle.fontName = @"Helvetica";
    self.graph.title = @"Click to Toggle Range Plot Style";
    self.graph.titleTextStyle = textStyle;
    self.graph.titleDisplacement = CGPointMake(0.0f, -20.0f);
    
    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    NSTimeInterval xLow = oneDay*0.5f;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(xLow) length:CPTDecimalFromFloat(oneDay*5.0f)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(1.0) length:CPTDecimalFromFloat(3.0)];
    
    // Axes
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    x.majorIntervalLength = CPTDecimalFromFloat(oneDay);
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"2");
    x.minorTicksPerInterval = 0;
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;
    CPTTimeFormatter *timeFormatter = [[[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter] autorelease];
    timeFormatter.referenceDate = refDate;
    x.labelFormatter = timeFormatter;
    
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength = CPTDecimalFromString(@"0.5");
    y.minorTicksPerInterval = 5;
    y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(oneDay);
    
    // Create a plot that uses the data source method
	CPTRangePlot *dataSourceLinePlot = [[[CPTRangePlot alloc] init] autorelease];
    dataSourceLinePlot.identifier = @"Date Plot";
    
	// Add line style
	CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
	lineStyle.lineWidth = 1.0f;
    lineStyle.lineColor = [CPTColor greenColor];
    barLineStyle = [lineStyle retain];
    dataSourceLinePlot.barLineStyle = barLineStyle;
    
    // Bar properties
	dataSourceLinePlot.barWidth = 10.0f;
	dataSourceLinePlot.gapWidth = 20.0f;
	dataSourceLinePlot.gapHeight = 20.0f;
    dataSourceLinePlot.dataSource = self;
    
    // Add plot
    [self.graph addPlot:dataSourceLinePlot];
    self.graph.defaultPlotSpace.delegate = (id)self;
    
    // Store area fill for use later
    CPTColor *transparentGreen = [[CPTColor greenColor] colorWithAlphaComponent:0.2];
    areaFill = [[CPTFill alloc] initWithColor:(id)transparentGreen];
    

}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return self.dataSourceSortedReadings.count;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    OmronDataRecord *record = [self.dataSourceSortedReadings objectAtIndex:index];
    NSDecimalNumber *num = [NSDecimalNumber decimalNumberWithString:[record systolicPressure]]; 
    return num;
}

#pragma mark NSNotification Observers

- (void)dataSyncOperationDidEnd:(NSNotification*)notif
{
    // Table Reload
    NSLog(@"[GraphViewController dataSyncOperationDidEnd] Data Source isSampleData %s", [mDataSource isSampleData] ? "yes":"no");
    
    self.dataSourceSortedReadings = [self.dataSource.readings sortedArrayUsingComparator:^(id a, id b) {
        NSDate *first = [(OmronDataRecord*)a readingDate];
        NSDate *second = [(OmronDataRecord*)b readingDate];
        return [first compare:second];
    }];
    
}

- (void)dataSyncOperationDataAvailable:(NSNotification*)notif
{
    // Table Reload
    NSLog(@"[GraphViewController dataSyncOperationDataAvailable] Data Source isSampleData %s", [mDataSource isSampleData] ? "yes":"no");
    
    self.dataSourceSortedReadings = [self.dataSource.readings sortedArrayUsingComparator:^(id a, id b) {
        NSDate *first = [(OmronDataRecord*)a readingDate];
        NSDate *second = [(OmronDataRecord*)b readingDate];
        return [first compare:second];
    }];

    
}


@end
