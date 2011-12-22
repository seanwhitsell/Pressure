#import "Controller.h"
#import <CorePlot/CorePlot.h>

static const CGFloat kZDistanceBetweenLayers = 20.0;

static NSString * const bindingsPlot = @"Bindings Plot";
static NSString * const dataSourcePlot = @"Data Source Plot";
static NSString * const barPlot1 = @"Bar Plot 1";
static NSString * const barPlot2 = @"Bar Plot 2";

@interface Controller ()

-(void)setupGraph;
-(void)setupAxes;
-(void)setupScatterPlots;
-(void)positionFloatingAxis;
-(void)setupBarPlots;

@end

#pragma mark -

@implementation Controller

@synthesize xShift;
@synthesize yShift;
@synthesize labelRotation;

+(void)initialize
{
    [NSValueTransformer setValueTransformer:[[CPTDecimalNumberValueTransformer new] autorelease] forName:@"CPTDecimalNumberValueTransformer"];
}

-(void)dealloc 
{
    [graph release];
    [super dealloc];
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    self.xShift = 0.0;
    self.yShift = 0.0;

	[self setupGraph];
    [self setupAxes];
    [self setupScatterPlots];
    [self positionFloatingAxis];
	[self setupBarPlots];
}

-(id)newObject 
{
	NSNumber *x1 = [NSDecimalNumber numberWithDouble:1.0 + ((NSMutableArray *)self.content).count * 0.05];
	NSNumber *y1 = [NSDecimalNumber numberWithDouble:1.2 * rand()/(double)RAND_MAX + 1.2];
    return [[NSMutableDictionary dictionaryWithObjectsAndKeys:x1, @"x", y1, @"y", nil] retain];
}

#pragma mark -
#pragma mark Graph Setup Methods

-(void)setupGraph
{
    // Create graph and apply a dark theme
    graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:NSRectToCGRect(hostView.bounds)];
	CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
    [graph applyTheme:theme];
	hostView.hostedGraph = graph;
    
    // Graph title
    graph.title = @"This is the Graph Title\nThis is the Second Line";
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [CPTColor grayColor];
    textStyle.fontName = @"Helvetica-Bold";
    textStyle.fontSize = 18.0;
	textStyle.textAlignment = CPTTextAlignmentCenter;
    graph.titleTextStyle = textStyle;
    graph.titleDisplacement = CGPointMake(0.0, 25.0);
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
	
    // Graph padding
    graph.paddingLeft = 60.0;
    graph.paddingTop = 60.0;
    graph.paddingRight = 60.0;
    graph.paddingBottom = 60.0;    
}

-(void)setupAxes
{
    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.delegate = self;
    
    // Grid line styles
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.75;
    majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
    
    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 0.25;
    minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];    
    
    CPTMutableLineStyle *redLineStyle = [CPTMutableLineStyle lineStyle];
    redLineStyle.lineWidth = 10.0;
    redLineStyle.lineColor = [[CPTColor redColor] colorWithAlphaComponent:0.5];
    
    // Axes
    // Label x axis with a fixed interval policy
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    x.majorIntervalLength = CPTDecimalFromString(@"0.5");
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"2");
    x.minorTicksPerInterval = 2;
    x.majorGridLineStyle = majorGridLineStyle;
    x.minorGridLineStyle = minorGridLineStyle;
	NSArray *exclusionRanges = [NSArray arrayWithObjects:
                                [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(1.99) length:CPTDecimalFromFloat(0.02)], 
                                [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.99) length:CPTDecimalFromFloat(0.02)],
                                [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(2.99) length:CPTDecimalFromFloat(0.02)],
                                nil];
	x.labelExclusionRanges = exclusionRanges;
    
	x.title = @"X Axis\nLine 2";
	x.titleOffset = 30.0;
	x.titleLocation = CPTDecimalFromString(@"3.0");
    
	// Label y with an automatic label policy. 
    CPTXYAxis *y = axisSet.yAxis;
    y.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    y.orthogonalCoordinateDecimal = CPTDecimalFromString(@"2");
    y.minorTicksPerInterval = 2;
    y.preferredNumberOfMajorTicks = 8;
    y.majorGridLineStyle = majorGridLineStyle;
    y.minorGridLineStyle = minorGridLineStyle;
    y.labelOffset = 10.0;
	exclusionRanges = [NSArray arrayWithObjects:
                       [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(1.99) length:CPTDecimalFromFloat(0.02)], 
                       [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.99) length:CPTDecimalFromFloat(0.02)],
                       [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(3.99) length:CPTDecimalFromFloat(0.02)],
                       nil];
	y.labelExclusionRanges = exclusionRanges;
    
	y.title = @"Y Axis\nLine 2";
	y.titleOffset = 30.0;
	y.titleLocation = CPTDecimalFromString(@"2.7");
    
    // Rotate the labels by 45 degrees, just to show it can be done.
	self.labelRotation = M_PI * 0.25;
    
    // Add an extra y axis (red)
    // We add constraints to this axis below
    CPTXYAxis *y2 = [[(CPTXYAxis *)[CPTXYAxis alloc] initWithFrame:CGRectZero] autorelease];
    y2.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    y2.orthogonalCoordinateDecimal = CPTDecimalFromString(@"3");
    y2.minorTicksPerInterval = 0;
    y2.preferredNumberOfMajorTicks = 4;
    y2.majorGridLineStyle = majorGridLineStyle;
    y2.minorGridLineStyle = minorGridLineStyle;
    y2.labelOffset = 10.0;    
    y2.coordinate = CPTCoordinateY;
    y2.plotSpace = graph.defaultPlotSpace;
    y2.axisLineStyle = redLineStyle;
    y2.majorTickLineStyle = redLineStyle;
    y2.minorTickLineStyle = nil;
    y2.labelTextStyle = nil;
    y2.visibleRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(2) length:CPTDecimalFromInteger(3)];
	y2.title = @"Y2 title";
	y2.titleLocation = CPTDecimalFromInteger(3);    
    // Set axes
    graph.axisSet.axes = [NSArray arrayWithObjects:x, y, y2, nil];    
}

-(void)setupScatterPlots
{
    // Create one plot that uses bindings
	CPTScatterPlot *boundLinePlot = [[[CPTScatterPlot alloc] init] autorelease];
    boundLinePlot.identifier = bindingsPlot;
    
    CPTMutableLineStyle *lineStyle = [[boundLinePlot.dataLineStyle mutableCopy] autorelease];
	lineStyle.miterLimit = 1.0;
	lineStyle.lineWidth = 3.0;
	lineStyle.lineColor = [CPTColor blueColor];
    boundLinePlot.dataLineStyle = lineStyle;
    
    [graph addPlot:boundLinePlot];
	[boundLinePlot bind:CPTScatterPlotBindingXValues toObject:self withKeyPath:@"arrangedObjects.x" options:nil];
	[boundLinePlot bind:CPTScatterPlotBindingYValues toObject:self withKeyPath:@"arrangedObjects.y" options:nil];
    
    // Put an area gradient under the plot above
    NSString *pathToFillImage = [[NSBundle mainBundle] pathForResource:@"BlueTexture" ofType:@"png"];
    CPTImage *fillImage = [CPTImage imageForPNGFile:pathToFillImage];
    fillImage.tiled = YES;
    CPTFill *areaGradientFill = [CPTFill fillWithImage:fillImage];
    boundLinePlot.areaFill = areaGradientFill;
    boundLinePlot.areaBaseValue = [[NSDecimalNumber one] decimalValue];
    
	// Add plot symbols
	CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
	symbolLineStyle.lineColor = [CPTColor blackColor];
	CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
	plotSymbol.fill = [CPTFill fillWithColor:[CPTColor blueColor]];
	plotSymbol.lineStyle = symbolLineStyle;
    plotSymbol.size = CGSizeMake(10.0, 10.0);
    boundLinePlot.plotSymbol = plotSymbol;
    
    // Set plot delegate, to know when symbols have been touched
	// We will display an annotation when a symbol is touched
    boundLinePlot.delegate = self; 
    boundLinePlot.plotSymbolMarginForHitDetection = 5.0f;
    
    // Create a second plot that uses the data source method
	CPTScatterPlot *dataSourceLinePlot = [[[CPTScatterPlot alloc] init] autorelease];
    dataSourceLinePlot.identifier = dataSourcePlot;
	dataSourceLinePlot.cachePrecision = CPTPlotCachePrecisionDouble;
    
    lineStyle = [[dataSourceLinePlot.dataLineStyle mutableCopy] autorelease];
	lineStyle.lineWidth = 1.0;
    lineStyle.lineColor = [CPTColor greenColor];
    dataSourceLinePlot.dataLineStyle = lineStyle;
    
    dataSourceLinePlot.dataSource = self;
    
	CPTMutableTextStyle *whiteTextStyle = [CPTMutableTextStyle textStyle];
    whiteTextStyle.color = [CPTColor whiteColor];
	dataSourceLinePlot.labelTextStyle = whiteTextStyle;
    
	dataSourceLinePlot.labelOffset = 5.0;
	dataSourceLinePlot.labelRotation = M_PI_4;
    [graph addPlot:dataSourceLinePlot];
    
    // Make the data source line use stepped interpolation
    dataSourceLinePlot.interpolation = CPTScatterPlotInterpolationStepped;
    
    // Put an area gradient under the plot above
    CPTColor *areaColor = [CPTColor colorWithComponentRed:0.3 green:1.0 blue:0.3 alpha:0.8];
    CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:[CPTColor clearColor]];
    areaGradient.angle = -90.0;
    areaGradientFill = [CPTFill fillWithGradient:areaGradient];
    dataSourceLinePlot.areaFill = areaGradientFill;
    dataSourceLinePlot.areaBaseValue = CPTDecimalFromString(@"1.75");
	
    // Add some initial data
	NSMutableArray *contentArray = [NSMutableArray arrayWithCapacity:100];
	for ( NSUInteger i = 0; i < 60; i++ ) {
		id x = [NSDecimalNumber numberWithDouble:1.0 + i * 0.05];
		id y = [NSDecimalNumber numberWithDouble:1.2 * rand()/(double)RAND_MAX + 1.2];
		[contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
	}
	self.content = contentArray;
    
    // Auto scale the plot space to fit the plot data
    // Extend the y range by 10% for neatness
    CPTXYPlotSpace *plotSpace = (id)graph.defaultPlotSpace;
    [plotSpace scaleToFitPlots:[NSArray arrayWithObjects:boundLinePlot, dataSourceLinePlot, nil]];
    CPTPlotRange *xRange = plotSpace.xRange;
    CPTPlotRange *yRange = plotSpace.yRange;
    [yRange expandRangeByFactor:CPTDecimalFromDouble(1.1)];
    plotSpace.yRange = yRange;
    
    // Restrict y range to a global range
    CPTPlotRange *globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f) length:CPTDecimalFromFloat(6.0f)];
    plotSpace.globalYRange = globalYRange;
    
    // set the x and y shift to match the new ranges
	CGFloat length = xRange.lengthDouble;
	self.xShift = length - 3.0;
	length = yRange.lengthDouble;
	self.yShift = length - 2.0;    
}

-(void)positionFloatingAxis
{
    // Position y2 axis relative to the plot area, ie, not moving when dragging
    CPTXYAxis *y2 = [graph.axisSet.axes objectAtIndex:2];
	y2.axisConstraints = [CPTConstraints constraintWithUpperOffset:150.0];
}

-(void)setupBarPlots
{    
	// Add plot space for horizontal bar charts
    CPTXYPlotSpace *barPlotSpace = [[CPTXYPlotSpace alloc] init];
    barPlotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-20.0f) length:CPTDecimalFromFloat(200.0f)];
    barPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-7.0f) length:CPTDecimalFromFloat(15.0f)];
	[graph addPlotSpace:barPlotSpace];
    [barPlotSpace release];
    
    // First bar plot
    CPTMutableTextStyle *whiteTextStyle = [CPTMutableTextStyle textStyle];
    whiteTextStyle.color = [CPTColor whiteColor];
    CPTBarPlot *barPlot = [CPTBarPlot tubularBarPlotWithColor:[CPTColor darkGrayColor] horizontalBars:YES];
    barPlot.baseValue = CPTDecimalFromFloat(20.0f);
    barPlot.dataSource = self;
    barPlot.barOffset = CPTDecimalFromFloat(-0.25f);
    barPlot.identifier = barPlot1;
	barPlot.plotRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.0) length:CPTDecimalFromDouble(7.0)];
    barPlot.labelTextStyle = whiteTextStyle;
    [graph addPlot:barPlot toPlotSpace:barPlotSpace];
    
    // Second bar plot
    barPlot = [CPTBarPlot tubularBarPlotWithColor:[CPTColor blueColor] horizontalBars:YES];
    barPlot.dataSource = self;
    barPlot.baseValue = CPTDecimalFromFloat(20.0f);
    barPlot.barOffset = CPTDecimalFromFloat(0.25f);
    barPlot.cornerRadius = 2.0;
    barPlot.identifier = barPlot2;
	barPlot.plotRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.0) length:CPTDecimalFromDouble(7.0)];
	barPlot.delegate = self;
    [graph addPlot:barPlot toPlotSpace:barPlotSpace];
}

#pragma mark -
#pragma mark Actions

-(IBAction)reloadDataSourcePlot:(id)sender
{
    CPTPlot *plot = [graph plotWithIdentifier:dataSourcePlot];
    [plot reloadData];
}

-(IBAction)removeData:(id)sender
{
	NSUInteger index = self.selectionIndex;
	
	if ( index != NSNotFound ) {
		[self removeObjectAtArrangedObjectIndex:index];
		
		CPTPlot *plot = [graph plotWithIdentifier:dataSourcePlot];
		[plot deleteDataInIndexRange:NSMakeRange(index, 1)];
	}
}

-(IBAction)insertData:(id)sender
{
	NSUInteger index = self.selectionIndex;
	
	if ( index != NSNotFound ) {
		id newData = [self newObject];
		[self insertObject:newData atArrangedObjectIndex:index];
		[newData release];
		
		CPTPlot *plot = [graph plotWithIdentifier:dataSourcePlot];
		[plot insertDataAtIndex:index numberOfRecords:1];
	}
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    if ( [plot isKindOfClass:[CPTBarPlot class]] ) 
        return 8;
    else
        return [self.arrangedObjects count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSNumber *num;
    if ( [plot isKindOfClass:[CPTBarPlot class]] ) {
        num = [NSDecimalNumber numberWithInt:(index+1)*(index+1)];
        if ( [plot.identifier isEqual:barPlot2] ) 
            num = [(NSDecimalNumber *)num decimalNumberBySubtracting:[NSDecimalNumber decimalNumberWithString:@"10"]];
    }
    else {
        num = [[self.arrangedObjects objectAtIndex:index] valueForKey:(fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y")];
        if ( fieldEnum == CPTScatterPlotFieldY ) {
			num = [NSNumber numberWithDouble:([num doubleValue] + 1.0)];	
		}
    }
    return num;
}

-(CPTFill *)barFillForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index
{
	return nil;
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index 
{
	if ( [(NSString *)plot.identifier isEqualToString:barPlot2] )
		return (id)[NSNull null]; // Don't show any label
	else if ( [(NSString *)plot.identifier isEqualToString:barPlot1] && index < 4 ) 
        return (id)[NSNull null];
    else if ( index % 4 ) {
        return (id)[NSNull null];
	}
	else {
		return nil; // Use default label style
	}
}

#pragma mark -
#pragma mark Plot Space Delegate Methods

-(CPTPlotRange *)plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate {
    // Impose a limit on how far user can scroll in x
    if ( coordinate == CPTCoordinateX ) {
        CPTPlotRange *maxRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-1.0f) length:CPTDecimalFromFloat(6.0f)];
        CPTPlotRange *changedRange = [[newRange copy] autorelease];
        [changedRange shiftEndToFitInRange:maxRange];
        [changedRange shiftLocationToFitInRange:maxRange];
        newRange = changedRange;
    }
    
    return newRange;
}

#pragma mark -
#pragma mark CPTScatterPlot delegate method

-(void)scatterPlot:(CPTScatterPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)index
{
	if ( symbolTextAnnotation ) {
        [graph.plotAreaFrame.plotArea removeAnnotation:symbolTextAnnotation];
        symbolTextAnnotation = nil;
    }
    
    // Setup a style for the annotation
    CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
    hitAnnotationTextStyle.color = [CPTColor whiteColor];
    hitAnnotationTextStyle.fontSize = 16.0f;
    hitAnnotationTextStyle.fontName = @"Helvetica-Bold";
    
    // Determine point of symbol in plot coordinates
    NSNumber *x = [[self.arrangedObjects objectAtIndex:index] valueForKey:@"x"];
    NSNumber *y = [[self.arrangedObjects objectAtIndex:index] valueForKey:@"y"];
	NSArray *anchorPoint = [NSArray arrayWithObjects:x, y, nil];
    
    // Add annotation
    // First make a string for the y value
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setMaximumFractionDigits:2];
    NSString *yString = [formatter stringFromNumber:y];
    
    // Now add the annotation to the plot area
    CPTTextLayer *textLayer = [[[CPTTextLayer alloc] initWithText:yString style:hitAnnotationTextStyle] autorelease];
    symbolTextAnnotation = [[[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:anchorPoint] autorelease];
	symbolTextAnnotation.contentLayer = textLayer;
    symbolTextAnnotation.displacement = CGPointMake(0.0f, 20.0f);
    [graph.plotAreaFrame.plotArea addAnnotation:symbolTextAnnotation];    
}

#pragma mark -
#pragma mark CPTBarPlot delegate method

-(void)barPlot:(CPTBarPlot *)plot barWasSelectedAtRecordIndex:(NSUInteger)index
{
	NSLog(@"barWasSelectedAtRecordIndex %lu", index);

	if ( symbolTextAnnotation ) {
        [graph.plotAreaFrame.plotArea removeAnnotation:symbolTextAnnotation];
        symbolTextAnnotation = nil;
    }
    
    // Setup a style for the annotation
    CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
    hitAnnotationTextStyle.color = [CPTColor redColor];
    hitAnnotationTextStyle.fontSize = 16.0f;
    hitAnnotationTextStyle.fontName = @"Helvetica-Bold";
    
    // Determine point of symbol in plot coordinates
	
    NSNumber *x = [NSNumber numberWithInt:0];
	NSNumber *y = [self numberForPlot:plot field:0 recordIndex:index];
	NSArray *anchorPoint = [NSArray arrayWithObjects:x, [NSNumber numberWithInt:index], nil];
    
    // Add annotation
    // First make a string for the y value
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setMaximumFractionDigits:2];
    NSString *yString = [formatter stringFromNumber:y];
	
    // Now add the annotation to the plot area
    CPTTextLayer *textLayer = [[[CPTTextLayer alloc] initWithText:yString style:hitAnnotationTextStyle] autorelease];
    symbolTextAnnotation = [[[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:plot.plotSpace anchorPlotPoint:anchorPoint] autorelease];
	symbolTextAnnotation.contentLayer = textLayer;
    symbolTextAnnotation.displacement = CGPointMake(0.0f, 0.0f);
    [graph.plotAreaFrame.plotArea addAnnotation:symbolTextAnnotation];    

	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"barWidthScale"];
	animation.duration = 0.25;
	animation.toValue = [NSNumber numberWithDouble:0.0];
	animation.repeatCount = 1;
	animation.autoreverses = YES;
	animation.removedOnCompletion = YES;
	[plot addAnimation:animation forKey:@"barWidthScale"];
}

#pragma mark -
#pragma mark PDF / image export

-(IBAction)exportToPDF:(id)sender
{
	NSSavePanel *pdfSavingDialog = [NSSavePanel savePanel];
	[pdfSavingDialog setRequiredFileType:@"pdf"];
	
	if ( [pdfSavingDialog runModalForDirectory:nil file:nil] == NSOKButton )
	{
		NSData *dataForPDF = [graph dataForPDFRepresentationOfLayer];
		[dataForPDF writeToFile:[pdfSavingDialog filename] atomically:NO];
	}		
}

-(IBAction)exportToPNG:(id)sender
{
	NSSavePanel *pngSavingDialog = [NSSavePanel savePanel];
	[pngSavingDialog setRequiredFileType:@"png"];
	
	if ( [pngSavingDialog runModalForDirectory:nil file:nil] == NSOKButton ) {
		NSImage *image = [graph imageOfLayer];
        NSData *tiffData = [image TIFFRepresentation];
        NSBitmapImageRep *tiffRep = [NSBitmapImageRep imageRepWithData:tiffData];
        NSData *pngData = [tiffRep representationUsingType:NSPNGFileType properties:nil];
		[pngData writeToFile:[pngSavingDialog filename] atomically:NO];
	}		
}

#pragma mark -
#pragma mark Layer exploding for illustration

-(IBAction)explodeLayers:(id)sender
{
	CATransform3D perspectiveRotation = CATransform3DMakeRotation(-40.0 * M_PI / 180.0, 0.0, 1.0, 0.0);
	
	perspectiveRotation = CATransform3DRotate(perspectiveRotation, -55.0 * M_PI / 180.0, perspectiveRotation.m11, perspectiveRotation.m21, perspectiveRotation.m31);
	
	perspectiveRotation = CATransform3DScale(perspectiveRotation, 0.7, 0.7, 0.7);
	
	graph.masksToBounds = NO;
	graph.superlayer.masksToBounds = NO;
	
	overlayRotationView = [(RotationView *)[RotationView alloc] initWithFrame:hostView.frame];
	overlayRotationView.rotationDelegate = self;
	overlayRotationView.rotationTransform = perspectiveRotation;
	[overlayRotationView setAutoresizingMask:[hostView autoresizingMask]];
	[[hostView superview] addSubview:overlayRotationView positioned:NSWindowAbove relativeTo:hostView];
	
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:1.0f] forKey:kCATransactionAnimationDuration];		

	[Controller recursivelySplitSublayersInZForLayer:graph depthLevel:0];
	graph.superlayer.sublayerTransform = perspectiveRotation;

	[CATransaction commit];
}

+(void)recursivelySplitSublayersInZForLayer:(CALayer *)layer depthLevel:(NSUInteger)depthLevel
{
	layer.zPosition = kZDistanceBetweenLayers * (CGFloat)depthLevel;
	layer.borderColor = [CPTColor blueColor].cgColor;
	layer.borderWidth = 2.0;
	
	depthLevel++;
	for (CALayer *currentLayer in layer.sublayers) {
		[Controller recursivelySplitSublayersInZForLayer:currentLayer depthLevel:depthLevel];
	}
}

-(IBAction)reassembleLayers:(id)sender
{
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:1.0f] forKey:kCATransactionAnimationDuration];		
	
	[Controller recursivelyAssembleSublayersInZForLayer:graph];
	graph.superlayer.sublayerTransform = CATransform3DIdentity;

	[CATransaction commit];
	
	[overlayRotationView removeFromSuperview];
	[overlayRotationView release];
	overlayRotationView = nil;
}

+(void)recursivelyAssembleSublayersInZForLayer:(CALayer *)layer
{
	layer.zPosition = 0.0;
	layer.borderColor = [CPTColor clearColor].cgColor;
	layer.borderWidth = 0.0;
	for (CALayer *currentLayer in layer.sublayers) {
		[Controller recursivelyAssembleSublayersInZForLayer:currentLayer];
	}
}

#pragma mark -
#pragma mark Demo windows

-(IBAction)plotSymbolDemo:(id)sender
{
	if ( !plotSymbolWindow ) {
		[NSBundle loadNibNamed:@"PlotSymbolDemo" owner:self];
	}
	
	[plotSymbolWindow makeKeyAndOrderFront:sender];
}

-(IBAction)axisDemo:(id)sender
{
	if ( !axisDemoWindow ) {
		[NSBundle loadNibNamed:@"AxisDemo" owner:self];
	}
	
	[axisDemoWindow makeKeyAndOrderFront:sender];
}

-(IBAction)selectionDemo:(id)sender
{
	if ( !selectionDemoWindow ) {
		[NSBundle loadNibNamed:@"SelectionDemo" owner:self];
	}
	
	[axisDemoWindow makeKeyAndOrderFront:sender];
}

#pragma mark -
#pragma mark CPTRotationDelegate delegate method

-(void)rotateObjectUsingTransform:(CATransform3D)rotationTransform
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];	

	graph.superlayer.sublayerTransform = rotationTransform;
	
	[CATransaction commit];
}

#pragma mark -
#pragma mark Accessors

-(void)setXShift:(CGFloat)newShift 
{
    xShift = newShift;
    CPTXYPlotSpace *space = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    CPTPlotRange *newRange = [[space.xRange copy] autorelease];
    newRange.length = CPTDecimalFromDouble(3.0 + newShift);  
	space.xRange = newRange;
}

-(void)setYShift:(CGFloat)newShift 
{
 	yShift = newShift;
    CPTXYPlotSpace *space = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    CPTPlotRange *newRange = [[space.yRange copy] autorelease];
    newRange.length = CPTDecimalFromDouble(2.0 + newShift);  
    space.yRange = newRange;
}

-(void)setLabelRotation:(CGFloat)newRotation 
{
 	labelRotation = newRotation;
	
	((CPTXYAxisSet *)graph.axisSet).yAxis.labelRotation = newRotation;
	[graph plotWithIdentifier:dataSourcePlot].labelRotation = newRotation;
}

@end
