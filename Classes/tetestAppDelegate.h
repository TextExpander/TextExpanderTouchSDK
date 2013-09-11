//
//  tetestAppDelegate.h
//  tetest
//
//  Created by Greg Scown on 8/24/09.
//  Copyright SmileOnMyMac 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class tetestViewController;

@interface tetestAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    tetestViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet tetestViewController *viewController;

@end

