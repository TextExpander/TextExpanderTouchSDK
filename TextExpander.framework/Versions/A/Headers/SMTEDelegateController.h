//
//  SMTEDelegateController.h
//  teiphone
//
//  Created by Greg Scown on 8/24/09.
//  Copyright 2009-2013 SmileOnMyMac. All rights reserved.
//

#import <UIKit/UIKit.h>

// Protocol to implement to support fill-in snippets
@protocol SMTEFillDelegate <NSObject>

/* When an abbreviation for a snippet that looks like a fill-in snippet has been
 * typed, SMTEDelegateController will call your fill delegate's implementation of
 * this method.
 * Provide some kind of identifier for the given UITextView/UITextField/UISearchBar/UIWebView
 * The ID doesn't have to be fancy, "maintext" or "searchbar" will do.
 *
 * Return nil to avoid the fill-in app-switching process (the snippet will be expanded
 * with "(field name)" where the fill fields are).
 *
 * Note that in the case of a UIWebView, the uiTextObject passed will actually be
 * a NSDictionary with two of these keys:
 *     - SMTEkWebView          The UIWebView object (key always present)
 *     - SMTEkElementID        The HTML element's id attribute (if found, preferred over Name)
 *     - SMTEkElementName      The HTML element's name attribute (if id not found and name found)
 * (If no id or name attribute is found, fill-in's cannot be supported, since there is
 * no way for TE to insert the filled-in text in the correct location after focus is lost.)
 * Unless there is only one editable area in your web view, this implies that the returned
 * identifier string should include element id/name information. Eg. "webview-field2".
 */
@required
- (NSString*)identifierForTextArea: (id)uiTextObject;

/* Usually called milliseconds after identifierForTextArea:, SMTEDelegateController is
 * about to call [[UIApplication sharedApplication] openURL: "tetouch-xc: *x-callback-url/fillin?..."]
 * In other words, the TEtouch is about to be activated. Your app should save state
 * and make any other preparations.
 *
 * This delegate method is optional, since "normal housekeeping" might save state anyway.
 *
 * The main difference between identifierForTextArea: and prepareForFillSwitch: is that
 * identifierForTextArea: is called when the snippet is triggered and based on the snippet
 * appearing to have fill-in fields, while prepareForFillSwitch: is called only if the
 * fill fields are known to be valid, and after the snippet abbreviation has been deleted from the text view/field.
 *
 * Return NO to cancel the process.
 */
@optional
- (BOOL)prepareForFillSwitch: (NSString*)textIdentifier;

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
@required
- (id)makeIdentifiedTextObjectFirstResponder: (NSString*)textIdentifier
							 fillWasCanceled: (BOOL)userCanceledFill
							  cursorPosition: (NSInteger*)ioInsertionPointLocation;

@end


@interface SMTEDelegateController : NSObject <UITextViewDelegate, UITextFieldDelegate, UIScrollViewDelegate, UIWebViewDelegate, UISearchBarDelegate> {
}
@property (nonatomic, assign) id nextDelegate;
@property (nonatomic, assign) BOOL provideUndoSupport; // Default: YES

// For nextDelegate, this flag is set for calls to shouldChangeChars... when a snippet is ready to expand
@property (nonatomic, readonly) BOOL isAttemptingToExpandText;

// Force plain-text expansion even if text attributes are enabled in the field/view - Default: NO
@property (nonatomic, assign) BOOL expandPlainTextOnly;

// URL scheme for fill-in snippet completion via x-callback-url. Leave nil to
// avoid the fill-in process.
@property (nonatomic, retain) NSString *fillCompletionScheme;
// The name of your app to be displayed in the fill-in window, ex. "SuperEditor"
@property (nonatomic, retain) NSString *fillForAppName;
@property (nonatomic, assign) NSObject<SMTEFillDelegate> *fillDelegate;

+ (BOOL)isTextExpanderTouchInstalled;		// is any version of TEt installed?
+ (BOOL)textExpanderTouchSupportsFillins;	// essentially, is TEt 2.0 or higher installed?

/*
 * Is TextExpander permitted to request access to Reminders? (default: YES)
 * If you turn this off, your app must handle access to Reminders and must alert
 * the user that access is required when they turn TextExpander on.
 */
+ (void)setAllowRemindersAccessRequest:(BOOL)allow;

/*
 * On iOS 6, returns YES if app has access to Reminders and the shared TextExpander
 * Data reminder is present OR if the shared UIPasteboard is available.
 * On iOS 7, returns YES only if app has access to Reminders and the shared TextExpander
 * Data reminder is present.
 */
+ (BOOL)snippetsAreShared;
+ (void)setExpansionEnabled:(BOOL)expansionEnabled;

/*
 * UIText___Delegate methods let TE know when the text selection range or insertion cursor position has
 * moved, but if your app has performed some manipulation of the text that does not generate delegate
 * calls, use this to reset the keyLog which is used to detect when an abbreviation has been typed.
 */
- (void)resetKeyLog;

/*
 * When your app becomes the active app, it means TEtouch may have been active, where the user might have
 * edited snippets, etc. This checks to see if snippets have been updated.
 */
- (void)willEnterForeground;

/*
 * stringByExpandingAbbreviations will expand any snippet abbreviations found in the inString.
 * That is, you could pass just "sig1" to get a signature snippet's expansion, or you could
 * pass "ddate is the time to call me at ttel" to get date and phone snippets into the text.
 *
 * Note that fill-in snippets are not supported in this expansion method (%fill macros in the 
 * snippet text will be replaced with "(variablename)".
 *
 * Note: in 1.2.3 and prior versions, stringByExpandingAbbreviations improperly returned a retained string
 */
- (NSString*)stringByExpandingAbbreviations:(NSString*)inString;

/*
 * attributedStringByExpandingAbbreviations works just like stringByExpandingAbbreviations, but
 * with attributed strings.
 * This method respects the expandPlainTextOnly flag -- if set, expansions will take on
 * the same attributes as their abbreviations.
 *
 * Note that fill-in snippets are not supported in this expansion method (%fill macros in the 
 * snippet text will be replaced with "(variablename)".
 *
 * In iOS versions prior to 6.0, this will expand the snippets as "plain" text (actually, in
 * text matching the style of the abbreviation).
 */
- (NSAttributedString*)attributedStringByExpandingAbbreviations:(NSAttributedString*)inString;

/*
 * If your app receives application:openURL:sourceApplication:annotation: or application:handleOpenURL:
 * for a fill-in callback, call this and (if the URL scheme matches fillCompletionScheme) the
 * SMTEDelegateController will handle the response to this URL and return YES.
 *
 * If the user completed the fill, first the filled-in snippet text is retrieved.
 * Then it will call the fillDelegate to activate the appropriate text view/field and insert any
 * text.
 *
 * Note: If you use multiple SMTEDelegateController's (for different text objects),
 * you can examine the [url query] and look for the textID parameter to find the identifier
 * your SMTEFillDelegate provided.
 * That is, this URL looks like: 
 *   fillCompletionScheme://x-callback-url/SMTEfilled?textID=[text area ID]&loc=[offset into text]&format=[1|0]
 *          with, possibly, &cursorPos=[adjust count]&selLen=[selection range if not empty]
 *    or
 *   fillCompletionScheme://x-callback-url/SMTEfillcanceled?textID=[text area ID]&loc=[offset into text]
 *    or
 *   fillCompletionScheme://x-callback-url/SMTEerror?textID=[text area ID]&loc=[offset into text]&error-Code=NNN&errorMessage=blah+blah+blah
 *
 * This method also supports a URL that looks like:
 *    [anyScheme]://x-callback-url/SMTEsetlog?log=[off|on|detailed]
 * to enable/disable logging
 */
- (BOOL)handleFillCompletionURL: (NSURL*)url;

@end

extern NSString *SMTEkWebView;		// dictionary key of UIWebView
extern NSString *SMTEkElementID;	// dictionary key of a string with an HTML element's id attribute
extern NSString *SMTEkElementName;	// dictionary key of a string with an HTML element's name attribute

