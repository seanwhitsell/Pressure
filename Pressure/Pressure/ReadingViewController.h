//
//  ReadingViewController.h
//  Pressure
//
//  Created by Sean Whitsell on 1/12/12.
//  Copyright (c) 2012 Cisco Systems, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXListView.h"

@class PXListView;
@class OmronDataSource;

@interface ReadingViewController : NSViewController <PXListViewDelegate>
{
    OmronDataSource *mDataSource;
    PXListView *mListView;
}

@property (nonatomic, readwrite, retain) OmronDataSource *dataSource;
@property (nonatomic, readwrite, assign) IBOutlet PXListView *listView;

- (IBAction)reloadTable:(id)sender;

@end
