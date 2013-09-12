//
//  tetestViewController.m
//  tetest
//
//  Created by Greg Scown on 8/24/09.
//  Copyright SmileOnMyMac 2009-2013. All rights reserved.
//

#import "tetestViewController.h"
#import "SMTEHTMLEditorController.h"
#import "tetestInputAccessoryView.h"
#import <AddressBook/AddressBook.h>
#import <CoreText/CoreText.h>
#import <EventKit/EventKit.h>

@implementation tetestViewController

@synthesize textView = _textView;
@synthesize textField = _textField;
@synthesize webView = _webView;
@synthesize searchBar = _searchBar;
@synthesize textExpander = _textExpander;

- (void)viewDidLoad {
	// Initialize the TextExpander delegate controller
	self.textExpander = [[[SMTEDelegateController alloc] init] autorelease];
	
	BOOL allowFormatting = ([NSParagraphStyle class] != nil);	// iOS 6 and above
    
	// Set the TextExpander delegate controller as the delegate for the text view
	[self.textView setDelegate:self.textExpander];
	if (allowFormatting) {
	    [self.textView setAllowsEditingTextAttributes:YES];	// So formatted snippets expand with their attributes
		NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:@"The quick brown fox." attributes:nil];
		UIColor *color = [UIColor redColor];
		[as addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(4, 5)];
		[self.textView setAttributedText:[[as copy] autorelease]];
	}
	else
		self.textView.text = @"The plain brown fox.";

	// Set up the text field the same way
	[self.textField setDelegate:self.textExpander];
	[self.textField setClearButtonMode:UITextFieldViewModeAlways];
	
	if (allowFormatting)
	    [self.textField setAllowsEditingTextAttributes:YES];

	[self.webView setDelegate:self.textExpander];

    NSURL *url = [NSURL URLWithString:@"http://smileonmymac.com/html/TextExpander/touch/sdkview.html"];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[self.webView loadRequest:request];

//    NSString* html = @"<body>TE Test<div><br></div><table><tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr></table><div>Before starting with a snippet</div><div><br></div></body>";
//    [webView loadHTMLString:html baseURL:[NSURL URLWithString:@"/"]];

	[self.searchBar setDelegate:self.textExpander];
	
	// Set ourself as the next delegate to be called after the TextExpander delegate controller
	[self.textExpander setNextDelegate:self];
	
	NSLog(@"TextExpander touch installed: %@", [SMTEDelegateController isTextExpanderTouchInstalled] ? @"YES" : @"NO");
    [SMTEDelegateController setAllowRemindersAccessRequest:NO];
	NSLog(@"TextExpander snippets are shared: %@", [SMTEDelegateController snippetsAreShared] ? @"YES" : @"NO");
    [SMTEDelegateController setAllowRemindersAccessRequest:YES];

    //NSString *testString = @"sig1Today is ddate. tyvm";
    //NSLog(@"stringByExpandingAbbreviations in %@: %@", testString, [textExpander stringByExpandingAbbreviations:testString]);
	
	// Support fill-in callbacks
	self.textExpander.fillCompletionScheme = @"tetester-fill-xc";	// (we have to declare and handle this)
	self.textExpander.fillForAppName = @"TEtouch SDK Tester";
	self.textExpander.fillDelegate = self;

	// Create an input accessory view for the textView (only on iPad due to limited screen space)
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		CGRect accessFrame = CGRectMake(0.0, 0.0, 768.0, 32.0);
		tetestInputAccessoryView *inputAcc = [[[tetestInputAccessoryView alloc] initWithFrame:accessFrame] autorelease];
		inputAcc.destTextView = self.textView;
		self.textView.inputAccessoryView = inputAcc;
	}

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:@"UIApplicationWillEnterForegroundNotification" object:nil];
	    
    [super viewDidLoad];
    
    [NSThread detachNewThreadSelector:@selector(alertIfNoRemindersAccess) toTarget:self withObject:nil];
}

- (void)willEnterForeground:(NSNotification*)notification {
	[self.textExpander willEnterForeground];
    [self alertIfNoRemindersAccess];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	// Release the TextExpander delegate controller allocated in viewDidLoad
	self.textExpander = nil;
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
    [super dealloc];
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
	if (self.textView == uiTextObject)
		result =  @"myTextView";
	if (self.textField == uiTextObject)
		result =  @"myTextField";
	if (self.searchBar == uiTextObject)
		result =  @"mySearchBar";
	if ([uiTextObject isKindOfClass: [NSDictionary class]]) {
		UIWebView *wv = [uiTextObject objectForKey: SMTEkWebView];
		if (self.webView == wv) {
			NSString *fieldInfo;
			if ((fieldInfo = [uiTextObject objectForKey: SMTEkElementID]) != nil)
				result = [NSString stringWithFormat: @"webview_ID:%@", fieldInfo];
			else if ((fieldInfo = [uiTextObject objectForKey: SMTEkElementName]) != nil)
				result = [NSString stringWithFormat: @"webview_Name:%@", fieldInfo];
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
	if ([@"myTextView" isEqualToString: textIdentifier]) {
		[self.textView becomeFirstResponder];
		UITextPosition *theLoc = [self.textView positionFromPosition: self.textView.beginningOfDocument
															  offset: *ioInsertionPointLocation];
		if (theLoc != nil)
			self.textView.selectedTextRange = [self.textView textRangeFromPosition: theLoc toPosition: theLoc];
		return self.textView;
	}
	if ([@"myTextField" isEqualToString: textIdentifier]) {
		[self.textField becomeFirstResponder];
		UITextPosition *theLoc = [self.textField positionFromPosition: self.textField.beginningOfDocument
															  offset: *ioInsertionPointLocation];
		if (theLoc != nil)
			self.textField.selectedTextRange = [self.textField textRangeFromPosition: theLoc toPosition: theLoc];
		return self.textField;
	}
	if ([@"mySearchBar" isEqualToString: textIdentifier]) {
		[self.searchBar becomeFirstResponder];
		// Note: UISearchBar does not support cursor positioning.
		// Since we don't save search bar text as part of our state, if our app was unloaded while TE was
		// presenting the fill-in window, the search bar might now be empty to we should return
		// insertionPointLocation of 0.
		NSInteger searchTextLen = [self.searchBar.text length];
		if (searchTextLen < *ioInsertionPointLocation)
			*ioInsertionPointLocation = searchTextLen;
		return self.searchBar;
	}
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
	return nil;
}

// The following are the UITextViewDelegate methods; they simply write to the console log for demonstration purposes

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
	NSLog(@"nextDelegate textViewShouldBeginEditing");
	return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	NSLog(@"nextDelegate textViewShouldEndEditing");
	return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	NSLog(@"nextDelegate textViewDidBeginEditing");
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	NSLog(@"nextDelegate textViewDidEndEditing");
}

- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (self.textExpander.isAttemptingToExpandText) {
        self.snippetExpanded = YES;
    }
	NSLog(@"nextDelegate textView:shouldChangeTextInRange: %@ originalText: %@ replacementText: %@", NSStringFromRange(range), [aTextView text], text);
	return YES;
}

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

// Workaround for what appears to be an iOS 7 bug which affects expansion of snippets
// whose content is greater than one line. The UITextView fails to update its display
// to show the full content. Try commenting this out and expanding "sig1" to see the issue.
//
// Given other oddities of UITextView on iOS 7, we had assumed this would be fixed along the way.
// Instead, we'll have to work up an isolated case and file a bug. We don't want to bake this kind
// of workaround into the SDK, so instead we provide an example here.
// If you have a better workaround suggestion, we'd love to hear it.
    
- (void)twiddleText:(UITextView*)textView {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [textView.textStorage edited:NSTextStorageEditedCharacters range:NSMakeRange(0, textView.textStorage.length) changeInLength:0];
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    if (self.snippetExpanded) {
        [self performSelector:@selector(twiddleText:) withObject:textView afterDelay:0.01];
        self.snippetExpanded = NO;
    }
	NSLog(@"nextDelegate textViewDidChange");
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
	NSLog(@"nextDelegate textViewDidChangeSelection");
}

// The following are the UITextFieldDelegate methods; they simply write to the console log for demonstration purposes

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	NSLog(@"nextDelegate textFieldShouldBeginEditing");
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	NSLog(@"nextDelegate textFieldDidBeginEditing");
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	NSLog(@"nextDelegate textFieldShouldEndEditing");
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	NSLog(@"nextDelegate textFieldDidEndEditing");
}

- (BOOL)textField:(UITextField *)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSLog(@"nextDelegate textField:shouldChangeCharactersInRange: %@ originalText: %@ replacementText: %@", NSStringFromRange(range),
		  aTextField.text, string);
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	NSLog(@"nextDelegate textFieldShouldClear");
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	NSLog(@"nextDelegate textFieldShouldReturn");
	return YES;
}

#if 0
// If your view supports zooming, your nextDelegate must include this method
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	NSLog(@"viewForZoomingInScrollView");
	return self.textView;
}
#endif
/*
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSLog(@"webView:shouldStartLoadWithRequest:navigationType:");
	return NO;
}
*/

- (void)webViewDidStartLoad:(UIWebView *)webView {
	NSLog(@"webViewDidStartLoad");
}

- (void)webViewDidFinishLoad:(UIWebView *)inWebView {
  //[inWebView stringByEvaluatingJavaScriptFromString:@"document.body.contentEditable ='true'; document.designMode='on';"];
	NSLog(@"webViewDidFinishLoad");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	NSLog(@"webView:didFailLoadWithError: %@", error);
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) inSearchBar {
	NSLog(@"searchBarCancelButtonClicked: %@", inSearchBar);
}

// (iPad-only because it's too big to display effectively on iPhone)
- (IBAction)testHTML: (id)sender {	
	// Display the HTML text editor for formatted text
	SMTEHTMLEditorController *htmlController = [[SMTEHTMLEditorController alloc] initWithNibName: nil bundle: nil];
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:htmlController];  
	navController.modalPresentationStyle = UIModalPresentationPageSheet;
	[self presentViewController: navController animated: ![sender isKindOfClass: [NSURL class]] completion: NULL];
	
	[htmlController release];
	[navController release];
}

- (BOOL)appHasAccessToReminders {
    __block BOOL result = NO;
    if ([[EKEventStore class] respondsToSelector:@selector(authorizationStatusForEntityType:)]) { // iOS 6+
        EKAuthorizationStatus authStatus = [[EKEventStore class] authorizationStatusForEntityType:EKEntityTypeReminder];
        if (authStatus == EKAuthorizationStatusAuthorized) {
            result = YES;
        }
    } else {
        result = YES;
    }
    return result;
}

- (void)alertIfNoRemindersAccess {
    if (![self appHasAccessToReminders]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Reminders Access Required", @"")
                                                                 message:NSLocalizedString(@"TextExpander support requires access to Reminders.\r\rVisit Settings > Privacy > Reminders to allow tetest to access Reminders.", @"")
                                                                delegate:nil
                                                       cancelButtonTitle:NSLocalizedString(@"OK", "OK")
                                                       otherButtonTitles:nil] autorelease];
            [alertView show];
        });
    }    
}

@end
