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
//  GraphViewController.h
//  Created by Sean Whitsell on 1/8/12.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>

@class OmronDataSource;

@interface GraphViewController : NSViewController <CPTPlotDataSource>
{
@private
    OmronDataSource *mDataSource;
    NSArray *mDataSourceSortedReadings;

    NSArray *mPlotData;
    CPTXYGraph *mGraph;
    CPTGraphHostingView *mHostView;
    CPTFill *mAreaFill;
    CPTLineStyle *mBarLineStyle;
    CPTScatterPlot *mDataSourceLinePlot;
    NSDate *mReferenceDate;
}

@property (nonatomic, readonly, retain) OmronDataSource *dataSource;
@property (nonatomic, readwrite, retain) IBOutlet CPTGraphHostingView *hostView;

- (id)initWithDatasource:(OmronDataSource*)aDataSource;

@end
