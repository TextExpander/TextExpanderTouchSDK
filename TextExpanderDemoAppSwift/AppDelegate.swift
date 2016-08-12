//
//  AppDelegate.swift
//  TextExpanderDemoAppSwift
//
//  Created by Greg Scown on 7/23/16.
//  Copyright © 2016 SmileOnMyMac, LLC. All rights reserved.
//

import UIKit
import TextExpander

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let textExpanderEnabled: Bool = NSUserDefaults.standardUserDefaults().boolForKey(SMConstants.SMTEExpansionEnabled)
        SMTEDelegateController.setExpansionEnabled(textExpanderEnabled)
        SMSwiftWorkarounds.disableCustomKeyboardExpansion()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        // See if it is a fill-in snippet callback
        if ("textexpanderdemoapp-fill-xc" == url.scheme) {
            let tabController: UITabBarController = (self.window!.rootViewController as! UITabBarController)
            let currentViewController: SMTextExpanderViewController = tabController.selectedViewController as! SMTextExpanderViewController
            let textExpander = currentViewController.textExpander
            if (textExpander?.handleFillCompletionURL(url) != nil) {
                return true
            }
        }
        if ("textexpanderdemoapp-get-snippets-xc" == url.scheme) {
            let tabController: UITabBarController = (self.window!.rootViewController as! UITabBarController)
            let currentViewController: SMTextExpanderViewController = tabController.selectedViewController as! SMTextExpanderViewController
            let textExpander = currentViewController.textExpander
            var error : NSError? = nil
            var cancel : ObjCBool = ObjCBool(false)
            if textExpander?.handleGetSnippetsURL(url, error: &error, cancelFlag: &cancel) == false {
                print("Failed to handle URL: user canceled: \(cancel ? "yes" : "no"), error: \(error)")
            }
            else {
                if cancel {
                    print("User cancelled get snippets")
                    NSUserDefaults.standardUserDefaults().setBool(false, forKey: SMConstants.SMTEExpansionEnabled)
                }
                else if error != nil {
                    print("Error updating TextExpander snippets: \(error)")
                }
                else {
                    print("Successfully updated TextExpander Snippets")
                }
                
                return true
            }
        }
        return false
    }
    
}

