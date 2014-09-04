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
// The name of your app to be displayed in the fetch settings and/or fill-in window, ex. "SuperEditor"
@property (nonatomic, retain) NSString *clientAppName;

@property (nonatomic, assign) id nextDelegate;
@property (nonatomic, assign) BOOL provideUndoSupport; // Default: YES

// For nextDelegate, this flag is set for calls to shouldChangeChars... when a snippet is ready to expand
@property (nonatomic, readonly) BOOL isAttemptingToExpandText;

// Force plain-text expansion even if text attributes are enabled in the field/view - Default: NO
@property (nonatomic, assign) BOOL expandPlainTextOnly;

// URL scheme for fill-in snippet completion via x-callback-url. Leave nil to
// avoid the fill-in process.
@property (nonatomic, retain) NSString *fillCompletionScheme;
@property (nonatomic, assign) NSObject<SMTEFillDelegate> *fillDelegate;

+ (BOOL)isTextExpanderTouchInstalled;		// is any version of TEt installed?
+ (BOOL)textExpanderTouchSupportsFillins;	// essentially, is TEt 2.0 or higher installed?

/**
 * On iOS 6, returns YES if the shared UIPasteboard is available.
 * On iOS 7, returns YES only if your app has already fetched shared snippet data and it
 * still resides in a persistent UIPasteboard.
 *
 * @param optionalModDate can return the modification date of the found settings, or nil
 *
 * @return YES if shared snippets can be accessed and are found
 */
+ (BOOL)snippetsAreShared: (NSDate**)optionalModDate;

/**
 * Tells whether snippet expansion is possible with current state of shared/fetched settings.
 *
 * That is, returns YES if snippets have either already been loaded, or if there is
 * non-zero-length data on the persistent UIPasteboard where shared snippets from a
 * previous fetch (iOS 7) or from Share Snippets in TEtouch (iOS 6).
 *
 * @param loadIfNotLoaded attempt to load snippets and settings if not yet loaded, or
 * if the shared UIPasteboard date does not match date of loaded snippets (date mismatch
 * only applies if pre-iOS 7 and your app did not call willEnterForeground)
 * Note: If set and not yet loaded, this will load the snippets synchronously on the current
 * dispatch queue. You can call this off of the main queue to avoid blocking if the user
 * has a large snippet collection.
 * Because loading may fail, this might return YES if loadIfNotLoaded is NO, then later
 * return NO if loading failed.
 *
 * @param optionalCount can return the number of _loaded_ snippets (can be zero with a
 * YES return value if the snippet pasteboard data has not been read in yet)
 *
 * @param optionalLoadedDate can return the modification date of the pasteboard data, or nil if no
 * pasteboard data is found
 *
 * @param optionalLoadError can return snippet load error if load has been attempted and failed
 *
 * @return YES if shared snippets can be accessed and are found
 */
+ (BOOL)expansionStatusForceLoad: (BOOL)loadIfNotLoaded
					snippetCount: (NSUInteger*)optionalCount
						loadDate: (NSDate**)optionalLoadedDate
						   error: (NSError**)optionalLoadError;

/**
 * Turn expansion off or on.
 *
 * @param New snippet abbreviation expansion setting
 */
+ (void)setExpansionEnabled:(BOOL)expansionEnabled;

/**
 * Determine if expansion is currently enabled or disabled.
 */
+ (BOOL)expansionEnabled;

/**
 * Turn expansion off or on for the TextExpander custom keyboard.
 * Applies only if custom keyboard is active and your application is in the foreground.
 *
 * @param New snippet abbreviation expansion setting
 */
+ (void)setCustomKeyboardExpansionEnabled:(BOOL)expansionEnabled NS_AVAILABLE_IOS(8_0);

/**
 * On iOS 7, if your app has at some point fetched shared snippet data, then it will reside
 * in a persistent named UIPasteboard, with your team ID invisibly pre-fixed to the name.
 *
 * If the user turns off TextExpander support in your app, you can call this method to clear
 * that UIPasteboard so your app/team will no longer be using any persistent storage for snippet data.
 * Note that because of the team ID, this will also apply to any of your other apps as well, so
 * use with caution.
 *
 * In iOS 5 and 6 this method just clears any loaded-in-memory snippet settings.
 */
+ (void)clearSharedSnippets;

/*
 * UIText___Delegate methods let TE know when the text selection range or insertion cursor position has
 * moved, but if your app has performed some manipulation of the text that does not generate delegate
 * calls, use this to reset the keyLog which is used to detect when an abbreviation has been typed.
 */
- (void)resetKeyLog;

/*
 * Deprecated on iOS 7.
 * When your app becomes the active app, it means TEtouch may have been active, where the user might have
 * edited snippets, etc. On iOS 5 and 6, this checks to see if snippets have been updated.
 */
- (void)willEnterForeground NS_DEPRECATED_IOS(3_0, 7_0);

/*
 * Tells if TextExpander 2.3 or above is installed, which means TextExpander can respond to
 * a getSnippets call.
 */
+ (BOOL)textExpanderTouchHasGetSnippetsCallbackURL;

/*
 * Your app's URL scheme to handle the getSnippets x-callback-url.
 * (This can be the same URL scheme that you set for the fillCompletionScheme)
 * You must declare a URL scheme and implement
 * - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
 *
 * In that implementation, the getSnippets call will result in your app receiving openURL with one of:
 *   getSnippetsScheme://x-callback-url/TextExpanderSettings?[params for the SDK]
 *    or
 *   getSnippetsScheme://x-callback-url/TextExpanderSettingscanceled   (user canceled or refused)
 *    or
 *   getSnippetsScheme://x-callback-url/TextExpanderSettingserror?error-Code=NNN&errorMessage=blah+blah+blah
 *
 * If the scheme matches, the [url.host isEqualToString: @"x-callback-url"], and the [url path] begins with /TextExpanderSettings,
 * then your openURL handler should call the SDK's handleGetSnippetsURL: with the url, and return the value it returns.
 */
@property (nonatomic, retain) NSString *getSnippetsScheme;

/*
 * Your app or extension's Application Group Identifier. If set, TextExpander will store and retrieve its snippet data
 * from [NSFileManager containerURLForSecurityApplicationGroupIdentifier:appGroupIdentifier] with a path component of
 * Library/Application Support/TextExpander
*/
@property (nonatomic, retain) NSString *appGroupIdentifier;

/*
 * Attempts to fetch/update shared snippets and settings from the TextExpander app.
 *
 * Returns YES if the openURL call to TextExpander's settings-fetching URL succeeded.
 * (That is, it returns more-or-less immediately. The settings will arrive when your app
 *  is re-activated.)
 *
 * After a brief switch to the TextExpander app, your app will be re-activated via a getSnippetsScheme URL.
 */
- (BOOL)getSnippets;

/*
 * Call this method to handle application:openURL: with a URL that begins with "[your getSnippetsScheme]://x-callback-url/SMTEsetting..."
 *
 * The returned value is what your app delegate should return from openURL (which is almost always YES, unless the URL seems
 * malformed)
 *
 * If YES is returned, and no error or cancel is indicated, you can call [SMTEdel expansionStatusForceLoad: NO snippetCount: &optionalCount loadDate: &loadedDate error: nil]
 * to display a "snippets updated December 6, 2013" or "22 snippets loaded" status message for the user.
 *
 * @param optionalReturnedError being non-nil indicates that (despite a YES returned indicating the URL was processed)
 * the snippets were not successfully fetched.
 *
 * @param optionalCancelFlag similarly indicates that the URL is valid, but the user canceled in TextExpander, so no snippets arrived.
 *
 * @return YES if the callback URL was valid, and application:openURL: should return YES.
 */
- (BOOL)handleGetSnippetsURL: (NSURL*)url error: (NSError**)optionalReturnedError cancelFlag: (BOOL*)optionalCancelFlag;

/**
 * Expands any snippet abbreviations found in the inString.
 * That is, you could pass just "sig1" to get a signature snippet's expansion, or you could
 * pass "ddate is the time to call me at ttel" to get date and phone snippets into the text.
 *
 * Note that fill-in snippets are not supported in this expansion method (%fill macros in the 
 * snippet text will be replaced with "(variablename)".
 *
 * Note: in 1.2.3 and prior versions, stringByExpandingAbbreviations improperly returned a retained string
 *
 * @param inString text to be examined for snippet abbreviations
 *
 * @return the string with any abbreviations expanded
 */
- (NSString*)stringByExpandingAbbreviations:(NSString*)inString;

typedef NS_OPTIONS(NSUInteger, SMTEExpansionOptions) {
    SMTEExpansionOptionIgnoreCase = 1
};

- (NSString*)stringByExpandingAbbreviations:(NSString*)inString cursorPosition:(NSUInteger*)cursorPosition options:(SMTEExpansionOptions)expansionOptions;

/**
 * Works just like stringByExpandingAbbreviations, but with attributed strings. Plain text snippets
 * simply take on the attributes of their abbreviations.
 *
 * This method respects the expandPlainTextOnly flag -- if set, all expansions will take on
 * the same attributes as their abbreviations.
 *
 * Note that fill-in snippets are not supported in this expansion method (%fill macros in the 
 * snippet text will be replaced with "(variablename)".
 *
 * In iOS versions prior to 6.0, this will expand the snippets as "plain" text (actually, in
 * text matching the style of the abbreviation).
 *
 * @param inString text to be examined for snippet abbreviations
 *
 * @return the string with any abbreviations expanded
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

