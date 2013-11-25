//
//  SMAppDelegate.m
//  TextExpanderDemoApp
//
//  Created by Greg Scown on 11/23/13.
//  Copyright (c) 2013 Greg Scown. All rights reserved.
//

#import "SMAppDelegate.h"
#import <TextExpander/SMTEDelegateController.h>

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
            NSLog(@"Failed to update TextExpander Snippets: user canceled: %@, error: %@", cancel ? @"yes" : @"no", error);
        } else {
            if (cancel) {
                NSLog(@"User cancelled get snippets");
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:SMTEExpansionEnabled];
            } else {
                NSLog(@"Successfully updated TextExpander Snippets");
            }
        }
    }
    return NO;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BOOL textExpanderEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:SMTEExpansionEnabled];
    [SMTEDelegateController setExpansionEnabled:textExpanderEnabled];
    return YES;
}
							
@end
