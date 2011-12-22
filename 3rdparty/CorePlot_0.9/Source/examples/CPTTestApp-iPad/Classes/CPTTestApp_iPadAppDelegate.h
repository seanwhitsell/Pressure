//
//  CPTTestApp_iPadAppDelegate.h
//  CPTTestApp-iPad
//
//  Created by Brad Larson on 4/1/2010.
//

#import <UIKit/UIKit.h>

@class CPTTestApp_iPadViewController;

@interface CPTTestApp_iPadAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    CPTTestApp_iPadViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet CPTTestApp_iPadViewController *viewController;

@end

