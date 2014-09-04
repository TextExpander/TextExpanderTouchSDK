//
//  SMFirstViewController.m
//  TextExpanderDemoApp
//
//  Created by Greg Scown on 11/23/13.
//  Copyright (c) 2013 Greg Scown. All rights reserved.
//

#import "SMFirstViewController.h"
#import <CoreText/CoreText.h>

@interface SMFirstViewController ()

@end

@implementation SMFirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupKeyboardDismissal]; // dismiss keyboard when we tap outside text input objects
    
    self.textExpander = [[SMTEDelegateController alloc] init];
    self.searchBar.delegate = self.textExpander;
    self.textField.delegate = self.textExpander;
    self.textView.delegate = self.textExpander;
    self.textExpander.nextDelegate = self;
    
    self.textExpander.clientAppName = @"TextExpanderDemoApp";
    self.textExpander.fillCompletionScheme = @"textexpanderdemoapp-fill-xc";
    self.textExpander.fillDelegate = self;
    self.textExpander.appGroupIdentifier = @"group.com.smileonmymac.textexpander.demoapp"; // !!! You must change this
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
    self.snippetExpanded = YES;
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
	return nil;
}

- (void)setupKeyboardDismissal {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:
     UIKeyboardWillShowNotification object:nil];
    
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:
     UIKeyboardWillHideNotification object:nil];
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                 action:@selector(didTapAnywhere:)];
}

-(void) keyboardWillShow:(NSNotification *) note {
    [self.view addGestureRecognizer:self.tapRecognizer];
}

-(void) keyboardWillHide:(NSNotification *) note {
    [self.view removeGestureRecognizer:self.tapRecognizer];
}

-(void)didTapAnywhere: (UITapGestureRecognizer*) recognizer {
    [recognizer.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 70000)
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [self.textView.textStorage edited:NSTextStorageEditedCharacters range:NSMakeRange(0, textView.textStorage.length) changeInLength:0];
    }
#endif
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

// The following are the UISearchBarDelegate methods; they simply write to the console log for demonstration purposes

- (void)searchBarCancelButtonClicked:(UISearchBar *) inSearchBar {
	NSLog(@"searchBarCancelButtonClicked: %@", inSearchBar);
}

@end
