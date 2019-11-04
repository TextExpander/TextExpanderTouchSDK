//
//  SMAppDelegate.m
//  TextExpanderDemoApp
//
//  Created by Greg Scown on 11/23/13.
//  Copyright (c) 2013 Greg Scown. All rights reserved.
//

#import "SMAppDelegate.h"
#import <TextExpander/SMTEDelegateController.h>
#import <notify.h>

static int SMAppDelegateCustomKeyboardWillAppearToken = 0;

@implementation SMAppDelegate

NSString *SMTEExpansionEnabled = @"SMTEExpansionEnabled";

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	// See if it is a fill-in snippet callback
	if ([@"textexpanderdemoapp-fill-xc" isEqualToString: url.scheme]) {
        UITabBarController *tabController = (UITabBarController*)self.window.rootViewController;
        UIViewController *currentViewController = tabController.selectedViewController;
        SMTEDelegateController *textExpander = [currentViewController performSelector:@selector(textExpander)];
		if ([textExpander handleFillCompletionURL: url]) {
			return YES;
		}
	}
    if ([@"textexpanderdemoapp-get-snippets-xc" isEqualToString: url.scheme]) {
        UITabBarController *tabController = (UITabBarController*)self.window.rootViewController;
        UIViewController *currentViewController = tabController.selectedViewController;
        SMTEDelegateController *textExpander = [currentViewController performSelector:@selector(textExpander)];
        NSError *error = nil;
        BOOL cancel = NO;
        if ([textExpander handleGetSnippetsURL:url error:&error cancelFlag:&cancel] == NO) {
            NSLog(@"Failed to handle URL: user canceled: %@, error: %@", cancel ? @"yes" : @"no", error);
        } else {
            if (cancel) {
                NSLog(@"User cancelled get snippets");
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:SMTEExpansionEnabled];
			} else if (error != nil) {
				NSLog(@"Error updating TextExpander snippets: %@", error);
	        } else {
                NSLog(@"Successfully updated TextExpander Snippets");
            }
			return YES;
        }
    }
    return NO;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BOOL textExpanderEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:SMTEExpansionEnabled];
    [SMTEDelegateController setExpansionEnabled:textExpanderEnabled];

    // Disable expansion by the custom keyboard, as we implement the SDK and so can do more
    // than the custom keyboard (i.e. work with system keyboards, support rich text, support
    // robust x-callback-url UI for fill-ins
    notify_register_dispatch("com.smileonmymac.tetouch.keyboard.viewWillAppear",
                             &SMAppDelegateCustomKeyboardWillAppearToken,
                             dispatch_get_main_queue(), ^(int t) {
                                 [SMTEDelegateController setCustomKeyboardExpansionEnabled:NO];
                             });
    
    return YES;
}

@end
