//
//  SMSecondViewController.m
//  TextExpanderDemoApp
//
//  Created by Greg Scown on 11/23/13.
//  Copyright (c) 2013 Greg Scown. All rights reserved.
//

#import "SMSecondViewController.h"

@interface SMSecondViewController ()

@end

@implementation SMSecondViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textExpander = [[SMTEDelegateController alloc] init];
    self.textExpander.clientAppName = @"TextExpanderDemoApp";
    self.textExpander.fillCompletionScheme = @"textexpanderdemoapp-fill-xc";
    self.textExpander.fillDelegate = self;
    self.textExpander.appGroupIdentifier = @"group.com.smileonmymac.textexpander.demoapp"; // !!! You must change this
    
    self.webView.delegate = self.textExpander;
    self.textExpander.nextDelegate = self;
    NSURL *url = [NSURL URLWithString:@"https://smilesoftware.com/static/tetouch/sdkview.html"];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[self.webView loadRequest:request];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	NSLog(@"webViewDidStartLoad");
}

- (void)webViewDidFinishLoad:(UIWebView *)inWebView {
	NSLog(@"webViewDidFinishLoad");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	NSLog(@"webView:didFailLoadWithError: %@", error);
}

//---------------------------------------------------------------
// These three methods implement the SMTEFillDelegate protocol to support fill-ins

/* When an abbreviation for a snippet that looks like a fill-in snippet has been
 * typed, SMTEDelegateController will call your fill delegate's implementation of
 * this method.
 * Provide some kind of identifier for the given UITextView/UITextField/UISearchBar/UIWebView
 * The ID doesn't have to be fancy, "maintext" or "searchbar" will do.
 * Return nil to avoid the fill-in app-switching process (the snippet will be expanded
 * with "(field name)" where the fill fields are).
 *
 * Note that in the case of a UIWebView, the uiTextObject passed will actually be
 * an NSDictionary with two of these keys:
 *     - SMTEkWebView          The UIWebView object (key always present)
 *     - SMTEkElementID        The HTML element's id attribute (if found, preferred over Name)
 *     - SMTEkElementName      The HTML element's name attribute (if id not found and name found)
 * (If no id or name attribute is found, fill-in's cannot be supported, as there is
 * no way for TE to insert the filled-in text.)
 * Unless there is only one editable area in your web view, this implies that the returned
 * identifier string needs to include element id/name information. Eg. "webview-field2".
 */
- (NSString*)identifierForTextArea: (id)uiTextObject {
	NSString *result = nil;
	if ([uiTextObject isKindOfClass: [NSDictionary class]]) {
		UIWebView *wv = [uiTextObject objectForKey: SMTEkWebView];
		if (self.webView == wv) {
			NSString *fieldInfo;
			if ((fieldInfo = [uiTextObject objectForKey: SMTEkElementID]) != nil)
				result = [NSString stringWithFormat: @"webview_ID:%@", fieldInfo];
			else if ((fieldInfo = [uiTextObject objectForKey: SMTEkElementName]) != nil)
				result = [NSString stringWithFormat: @"webview_Name:%@", fieldInfo];
            if (result == nil)
                result = @"myWebView";
		}
	}
	return result;
}

/* Usually called milliseconds after identifierForTextArea:, SMTEDelegateController is
 * about to call [[UIApplication sharedApplication] openURL: "tetouch-xc: *x-callback-url/fillin?..."]
 * In other words, the TEtouch is about to be activated. Your app should save state
 * and make any other preparations.
 *
 * Return NO to cancel the process.
 */
- (BOOL)prepareForFillSwitch: (NSString*)textIdentifier {
	// At this point the app should save state since TextExpander touch is about
	// to activate.
	// It especially needs to save the contents of the textview/textfield!
	return YES;
}

/* Restore active typing location and insertion cursor position to a text item
 * based on the identifier the fill delegate provided earlier.
 * (This call is made from handleFillCompletionURL: )
 *
 * In the case of a UIWebView, this method should build and return an NSDictionary
 * like the one sent to the fill delegate in identifierForTextArea: when the snippet
 * was triggered.
 * That is, you should make the UIWebView become first responder, then return an
 * NSDictionary with two of these keys:
 *     - SMTEkWebView          The UIWebView object (key must be present)
 *     - SMTEkElementID        The HTML element's id attribute (preferred over Name)
 *     - SMTEkElementName      The HTML element's name attribute (only if no id)
 * TE will use the same Javascripts that it uses to expand normal snippets to focus the appropriate
 * element and insert the filled text.
 *
 * Note 1: If your app is still loaded after returning from TEtouch's fill window,
 * probably no work needs to be done (the text item will still be the first
 * responder, and the insertion cursor position will still be the same).
 * Note 2: If the requested insertionPointLocation cannot be honored (ie. text has
 * been reset because of the app switching), then update it to whatever is reasonable.
 *
 * Return nil to cancel insertion of the fill-in text. Users will not expect a cancel
 * at this point unless userCanceledFill is set. Even in the cancel case, they will likely
 * expect the identified text object to become the first responder.
 */
- (id)makeIdentifiedTextObjectFirstResponder: (NSString*)textIdentifier
							 fillWasCanceled: (BOOL)userCanceledFill
							  cursorPosition: (NSInteger*)ioInsertionPointLocation;
{
	NSRange srchRange = [textIdentifier rangeOfString: @"webview_"];
	if (srchRange.location == 0) {
		[self.webView becomeFirstResponder];
		// TE should take care of moving focus to the identified field, but we need to build
		// a dictionary to identify the field
		srchRange = [textIdentifier rangeOfString: @"webview_ID:"];
		if (srchRange.location == 0) {
			return [NSDictionary dictionaryWithObjectsAndKeys: self.webView, SMTEkWebView,
					[textIdentifier substringFromIndex: NSMaxRange(srchRange)], SMTEkElementID, nil];
		}
		srchRange = [textIdentifier rangeOfString: @"webview_Name:"];
		if (srchRange.location == 0) {
			return [NSDictionary dictionaryWithObjectsAndKeys: self.webView, SMTEkWebView,
					[textIdentifier substringFromIndex: NSMaxRange(srchRange)], SMTEkElementName, nil];
		}
		return nil;
	}
    if ([@"myWebView" isEqualToString: textIdentifier]) {
        [self.webView becomeFirstResponder];
        return [NSDictionary dictionaryWithObjectsAndKeys: self.webView, SMTEkWebView,
                @"myWebView", SMTEkElementID, nil];
    }
	return nil;
}

@end
