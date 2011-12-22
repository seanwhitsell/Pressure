
#import "Controller.h"
#import <CorePlot/CorePlot.h>


@implementation Controller

-(void)dealloc 
{
	[plotData release];
    [graph release];
    [super dealloc];
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    // If you make sure your dates are calculated at noon, you shouldn't have to 
    // worry about daylight savings. If you use midnight, you will have to adjust
    // for daylight savings time.
    NSDate *refDate = [NSDate dateWithNaturalLanguageString:@"00:00 Oct 29, 2009"];
    NSTimeInterval oneDay = 24 * 60 * 60;

    // Create graph from theme
    graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:CGRectZero];
	CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
	[graph applyTheme:theme];
	hostView.hostedGraph = graph;
    
    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    NSTimeInterval xLow = 0.0f;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(xLow) length:CPTDecimalFromFloat(oneDay*3.0f)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(1.0) length:CPTDecimalFromFloat(3.0)];
    
    // Axes
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    x.majorIntervalLength = CPTDecimalFromFloat(oneDay);
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"2");
    x.minorTicksPerInterval = 3;
	
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;
    CPTTimeFormatter *myDateFormatter = [[[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter] autorelease];
    myDateFormatter.referenceDate = refDate;
    x.labelFormatter = myDateFormatter;

	NSDateFormatter *timeFormatter = [[[NSDateFormatter alloc] init] autorelease];
    timeFormatter.timeStyle = kCFDateFormatterShortStyle;
    CPTTimeFormatter *myTimeFormatter = [[[CPTTimeFormatter alloc] initWithDateFormatter:timeFormatter] autorelease];
    myTimeFormatter.referenceDate = refDate;
    x.minorTickLabelFormatter = myTimeFormatter;
//	x.minorTickLabelRotation = M_PI/2;
	
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength = CPTDecimalFromString(@"0.5");
    y.minorTicksPerInterval = 5;
    y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0.5*oneDay);
            
    // Create a plot that uses the data source method
	CPTScatterPlot *dataSourceLinePlot = [[[CPTScatterPlot alloc] init] autorelease];
    dataSourceLinePlot.identifier = @"Date Plot";

	CPTMutableLineStyle *lineStyle = [[dataSourceLinePlot.dataLineStyle mutableCopy] autorelease];
	lineStyle.lineWidth = 3.f;
    lineStyle.lineColor = [CPTColor greenColor];
    dataSourceLinePlot.dataLineStyle = lineStyle;
    
    dataSourceLinePlot.dataSource = self;
    [graph addPlot:dataSourceLinePlot];
    	
    // Add some data
	NSMutableArray *newData = [NSMutableArray array];
	NSUInteger i;
	for ( i = 0; i < 7; i++ ) {
		NSTimeInterval x = oneDay*i*0.5f;
		id y = [NSDecimalNumber numberWithFloat:1.2*rand()/(float)RAND_MAX + 1.2];
		[newData addObject:
        	[NSDictionary dictionaryWithObjectsAndKeys:
                [NSDecimalNumber numberWithFloat:x], [NSNumber numberWithInt:CPTScatterPlotFieldX], 
                y, [NSNumber numberWithInt:CPTScatterPlotFieldY], 
                nil]];
	}
	plotData = newData;
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return plotData.count;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSDecimalNumber *num = [[plotData objectAtIndex:index] objectForKey:[NSNumber numberWithInt:fieldEnum]];
    return num;
}

@end
