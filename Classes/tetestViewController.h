//
//  tetestViewController.h
//  tetest
//
//  Created by Greg Scown on 8/24/09.
//  Copyright SmileOnMyMac 2009-2013. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TextExpander/SMTEDelegateController.h>

@interface tetestViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate, SMTEFillDelegate> {
	UITextView *_textView;
	UITextField *_textField;
	UIWebView *_webView;
	UISearchBar *_searchBar;
	SMTEDelegateController *_textExpander;
	id foregroundObserver;
}

@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UITextField *textField;
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) SMTEDelegateController *textExpander;
@property (nonatomic, assign) BOOL snippetExpanded;

- (IBAction)testHTML: (id)sender;		// display the rich text HTML editor view

@end

