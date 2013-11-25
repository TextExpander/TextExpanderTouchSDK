//
//  SMThirdViewController.h
//  TextExpanderDemoApp
//
//  Created by Greg Scown on 11/23/13.
//  Copyright (c) 2013 Greg Scown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TextExpander/SMTEDelegateController.h>

@interface SMThirdViewController : UIViewController <UIWebViewDelegate, SMTEFillDelegate>

@property (nonatomic, retain) IBOutlet UIWebView *webView;

@property (nonatomic, retain) SMTEDelegateController *textExpander;

@end
