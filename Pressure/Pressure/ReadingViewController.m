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
//  ReadingTableViewController.m
//  Created by Sean Whitsell on 1/9/12.
//
#import "ReadingViewController.h"
#import "OmronDataSource.h"

@implementation ReadingViewController

@synthesize dataSource = mDataSource;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"ReadingViewController" bundle:nil];
    if (self) 
    {
        // Initialization code here.
    }
    
    return self;
}

- (void)viewWillAppear
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
}

- (void)viewDidAppear
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
}

- (void)viewWillDisappear
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
}

- (void)viewDidDisappear
{
	NSLog(@"<%p> %@", self, [NSString stringWithUTF8String:__func__]);
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return nil;
}

@end
