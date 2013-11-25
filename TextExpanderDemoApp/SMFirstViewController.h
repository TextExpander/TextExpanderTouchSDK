//
//  SMFirstViewController.h
//  TextExpanderDemoApp
//
//  Created by Greg Scown on 11/23/13.
//  Copyright (c) 2013 Greg Scown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TextExpander/SMTEDelegateController.h>

@interface SMFirstViewController : UIViewController <SMTEFillDelegate>

@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UITextField *textField;
@property (nonatomic, retain) IBOutlet UITextView *textView;

@property (nonatomic, retain) SMTEDelegateController *textExpander;

@property (assign) BOOL snippetExpanded;

@property (nonatomic, retain) UITapGestureRecognizer *tapRecognizer;

@end
