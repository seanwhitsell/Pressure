//
//  PlotGalleryAppDelegate-iPhone.h
//  Plot Gallery-iOS
//
//  Created by Jeff Buck on 10/17/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PlotGalleryAppDelegate_iPhone : NSObject <UIApplicationDelegate>
{
    UIWindow *window;
    UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end
