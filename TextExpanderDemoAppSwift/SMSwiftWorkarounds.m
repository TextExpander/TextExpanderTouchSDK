//
//  SMSwiftWorkarounds.m
//  TextExpanderDemoAppSwift
//
//  Created by Greg Scown on 7/24/16.
//  Copyright © 2016 SmileOnMyMac, LLC. All rights reserved.
//

#import "SMSwiftWorkarounds.h"
#import <TextExpander/TextExpander.h>
#import <notify.h>

@implementation SMSwiftWorkarounds

static int SMCustomKeyboardWillAppearToken = 0;

+ (void)disableCustomKeyboardExpansion {
    // Disable expansion by the custom keyboard, as we implement the SDK and so can do more
    // than the custom keyboard (i.e. work with system keyboards, support rich text, support
    // robust x-callback-url UI for fill-ins
    notify_register_dispatch("com.smileonmymac.tetouch.keyboard.viewWillAppear",
                             &SMCustomKeyboardWillAppearToken,
                             dispatch_get_main_queue(), ^(int t) {
                                 [SMTEDelegateController setCustomKeyboardExpansionEnabled:NO];
                             });
    
}

@end
