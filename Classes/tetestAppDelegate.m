//
//  tetestAppDelegate.m
//  tetest
//
//  Created by Greg Scown on 8/24/09.
//  Copyright SmileOnMyMac 2009-2013. All rights reserved.
//

#import "tetestAppDelegate.h"
#import "tetestViewController.h"
#import "SMTEDelegateController.h"
#import "SMTEHTMLEditorController.h"

@implementation tetestAppDelegate

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    window.rootViewController = viewController;
    [window makeKeyAndVisible];
	// Required for Undo support
	application.applicationSupportsShakeToEdit = YES;
	NSURL *xcURL;
	if (launchOptions != nil && (xcURL = [launchOptions objectForKey: UIApplicationLaunchOptionsURLKey]) != nil) {
		// Check to see if we are inserting a completed fill-in into the HTML editor
		NSRange srchRange = [[xcURL absoluteString] rangeOfString: @"HTMLview_"];
		if (srchRange.location != NSNotFound) {
			[self.viewController testHTML: xcURL];
		}
	}
	return YES;
}
 
- (void)applicationDidEnterBackground:(UIApplication*)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	/*
	 * This application demonstrates two methods of handling the [SMTEDelegateController willEnterForeground]
	 * call.
	 *
	 * - The tetestViewController adds a notification observer for UIApplicationWillEnterForegroundNotification
	 * in [tetestViewController viewDidLoad].
	 *
	 * - We check to see if the (iPad-only) HTML Editor view is visible here, and pass along the
	 * information directly to its SMTEDelegateController.
	 */
	UIViewController *visibleVC = self.viewController.presentedViewController;
	if (visibleVC != self.viewController && [visibleVC isKindOfClass: [UINavigationController class]]
		&& (visibleVC = ((UINavigationController*)visibleVC).visibleViewController) != nil
		&& [visibleVC isKindOfClass: [SMTEHTMLEditorController class]]) {
		[((SMTEHTMLEditorController*)visibleVC).textExpander willEnterForeground];
	}
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	// See if it is a fill-in snippet callback
	SMTEDelegateController *delegate = viewController.textExpander;
	if ([@"tetester-fill-xc" isEqualToString: url.scheme]) {
		// If it is the HTML rich text editor, we need to make sure it is visible
		NSRange srchRange = [[url absoluteString] rangeOfString: @"HTMLview_"];
		if (srchRange.location != NSNotFound) {
			UIViewController *visibleVC = self.viewController.presentedViewController;
			if ([visibleVC isKindOfClass: [UINavigationController class]])
				visibleVC = ((UINavigationController*)visibleVC).visibleViewController;
			if (![visibleVC isKindOfClass: [SMTEHTMLEditorController class]]) {
				[self.viewController testHTML: url];	// Try to get it presented immediately
				visibleVC = self.viewController.presentedViewController;
				if ([visibleVC isKindOfClass: [UINavigationController class]])
					visibleVC = ((UINavigationController*)visibleVC).visibleViewController;
			}
			if ([visibleVC isKindOfClass: [SMTEHTMLEditorController class]]
				&& [((SMTEHTMLEditorController*)visibleVC).textExpander handleFillCompletionURL: url]) {
				return YES;
			}
		}
		if ([delegate handleFillCompletionURL: url]) {
			return YES;
		}
	}
	return NO;
}

- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
