#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"

@interface CPTTestAppPieChartController : UIViewController <CPTPieChartDataSource, CPTPieChartDelegate> 
{
	@private
	CPTXYGraph *pieChart;
	NSMutableArray *dataForChart;
	NSTimer *timer;
}

@property(readwrite, retain, nonatomic) NSMutableArray *dataForChart;
@property(readwrite, retain, nonatomic) NSTimer *timer;

-(void)timerFired;

@end
