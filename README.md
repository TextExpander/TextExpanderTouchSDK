# TextExpander touch SDK
(Release notes are found at the bottom of this document.)

[Smile](http://smilesoftware.com/) provides the TextExpander framework to include TextExpander functionality in your iOS app, subject to the License Agreement below.

The teTouchSDK project is a working example app demonstrating how to add TextExpander functionality to your app.

[TextExpander touch SDK home page](http://smilesoftware.com/sdk)

[TextExpander touch home page](http://smilesoftware.com/TextExpander/touch/index.html)

[Basic tutorial](http://smile.clarify-it.com/d/lkwwdw)  (Note: Based on pre-2.0 version of the SDK -- useful for the basic setup, but you must implement steps described in [Acquiring / Updating Snippet Data][] below as snippet fetching has changed significantly)

[Fill-ins tutorial](http://smile.clarify-it.com/d/ehf7a4)

[Google Group tetouch-sdk (for announcements)](http://groups.google.com/group/tetouch-sdk)

### Prerequisites

- Xcode 4.3 or later
- iOS 5.1 or later
- [TextExpander touch](http://smilesoftware.com/cgi-bin/redirect.pl?product=tetouch&cmd=itunes) is needed if you wish to test with your own snippets. Without TextExpander touch, you'll be limited to testing with the default snippets, listed below under Default Abbreviations & Snippets and added via the Defaults.textexpander file.

### Getting Started / Build Notes

- Add the TextExpander.framework to your project [^1]
- Add these frameworks to your project if they're not already included:
    - AudioToolbox
    - CoreGraphics
    - CoreText
    - Foundation
    - UIKit
- Add Defaults.textexpander if you want to test without TextExpander touch

### TextExpanderDemoApp

TextExpanderDemoApp is an iPhone app, which demonstrates acquiring / updating snippet data via its Settings view, usage of TextExpander in UITextField, UITextView, UISearchBar, and UIWebView. It includes a regular web view and a content editable web view. It's not meant to be a model iOS app. It's meant to demonstrate TextExpander functionality so that you can see it in context and adopt it easily in your app. To dismiss the keyboard in the Text Views view, tap the blank area on either side of the UITextField.

### Acquiring / Updating Snippet Data###

As of November 25, 2013 (and SDK version 2.3), apps which implement the TextExpander touch SDK in iOS 7 or later must use an x-callback-url to acquire and update TextExpander snippet data in response to user action. This differs from the previous Reminders and persistent pasteboard methods, both of which have been retired by Apple. For background, see [this post](https://groups.google.com/forum/#!topic/tetouch-sdk/x_tQWItEDnk) on our Google Group.

To acquire / update snippet data, your app needs to:

1. Provide a URL scheme for getting snippets via x-callback-url:
    1. Set the getSnippetsScheme property of the SMTEDelegateController 
    2. Add the scheme to your app's Info in Xcode under "URL Types" (if not using an existing URL scheme -- see note below)
    3. Implement application:openURL:sourceApplication:annotation: or application:handleOpenURL: in your app delegate, and call [SMTEDelegateController handleGetSnippetsURL:error:cancelFlag:] with any URL's that have that scheme (or which meet the criteria as described in the note below)
    4. If cancelFlag is returned as true, the user has Share Snippets turned off in TextExpander and did not permit sharing temporarily when prompted. If error is not nil, an error occurred, and you should probably inform the user.
2. Add a user interface element to your app which, when touched, initiates acquisition / updating of snippet data by calling - [SMTEDelegateController getSnippets]
3. Set the clientAppName property of the SMTEDelegateController, which is used to display the name of your app in the TextExpander app, as might be the case when Share Snippets is turned off to identify which app is requesting snippet data and offering the user a choice to turn Share Snippets on or to cancel.

Note that you can use an existing URL scheme as your getSnippetsScheme if you want to. The callback URLs will look like these:

- getSnippetsScheme://x-callback-url/TextExpanderSettings*[more…]*

So you can easily examine the URL for the presence of x-callback-url in the URL host and /TextExpander as the prefix of the URL path to determine whether or not a given URL is a snippet data callback to your URL scheme.

To provide users information about the current status of TextExpander data, you can use `expansionStatusForceLoad:snippetCount:loadDate:error:` to obtain the last-obtained snippet settings'  modification date, or find that no snippet settings have yet been fetched.

Please note that it is possible, though unlikely, that your app will be unloaded when TextExpander touch is launched. You may find that you will need code before or after you call [SMTEDelegateController handleGetSnippetsURL:] to check your app's state and to restore it if necessary.

### Usage Notes

- **UITextView, UITextField**: instantiate SMTEDelegateController and set it as the delegate of the UITextView or UITextField. If the user has specified formatting for a snippet, the snippet's text attributes are included `if (iOS >= 6.0 && theView/Field.allowsEditingTextAttributes && !SMTEDelegate.expandPlainTextOnly)`
- **UIWebView**: instantiate SMTEDelegateController and set it as the delegate of the UIWebView. If the user has specified formatting for a snippet, the snippet's text attributes are included `if (theKeyEvent.target.value is undefined && !SMTEDelegate.expandPlainTextOnly)`. (That is, formatting is allowed if the typing is not in an &lt;input type="text"&gt; or &lt;textarea&gt;)
- **UISearchBar**: instantiate SMTEDelegateController and set it as the delegate of the UISearchBar
- To add your own delegate to a UITextView/Field/SearchBar, call -[SMTEDelegateController setNextDelegate:] on the instance you created. Your delegate will be called after TextExpander has a chance to process the delegate calls. In the shouldChangeText/CharactersInRange: call, you can examine SMTEDelegate.isAttemptingToExpandText to see if TextExpander is going to expand a snippet based on the current character(s) being inserted. Returning NO will prevent that snippet expansion.
- A single SMTEDelegateController can service many UITextViews, UITextFields, UIWebViews, and UISearchBars. If you use setNextDelegate for multiple views or fields, please be sure to test the view or field passed to your delegate and respond accordingly.
- Look at the example app's file SMFirstViewController.m and SMSecondViewController.m to see examples of all these.

### Handling Attributed Text

As of iOS 6, UITextView and UITextField both implement an attributedText property. Even if your app leaves all the text in the view/field formatted the same way, TextExpander has no way to know that, so in order to retain any formatting of the existing text when it performs expansions, it inserts the snippet text into an NSMutableAttributedString copied from attributedText, then calls setAttributedText:

However, setAttributedText: has some undesirable Undo/Redo side-effects:
    - it clears the Undo state (unlike setText:)
    - it locks up if called during an Undo or Redo operation

If your UITextView does not offer allowsEditingTextAttributes then TextExpander will expand only the "plain text" versions of snippets but, as mentioned above, it uses setAttributedText: to retain existing formatting. To avoid calls to setAttributedText: you can subclass UITextView or UITextField and implement these two methods:

	- (NSAttributedString\*)textExpanderAttributedString;
	- (void)textExpanderSetAttributedString: (NSAttributedString\*)newText;

As of SDK version 2.0.1, TextExpander will prefer those methods over attributedText/setAttributedText: if your UITextView/Field implements them.

In the simplest case, where your view is all formatted the same way, these methods can be as simple as:

	-(NSAttributedString\*)textExpanderAttributedString {
		return self.attributedText;
	}
	-(void)textExpanderSetAttributedString: (NSAttributedString\*)newText {
		self.text = [newText string];
	}

(Note: To avoid locking up when performing a snippet expansion Undo using setAttributedText:, TextExpander uses `dispatch_async(dispatch_get_main_queue(), ^{ blah setAttributedText: changedText }); `)

### Supporting Fill-in Snippets

The above instructions support normal snippets, where the abbreviation characters that a user types are immediately expanded to snippet content. TEtouch 2.0 and above also supports fill-in snippets. Fill-ins allow the user to set up a longer snippet with a one or more variable fields embedded, which can be text fields, conditionally included sections, and popup menus to choose among selected options.

The fill-in process involves the use of x-callback URLs (thanks Greg Pierce of Agile Tortoise!) to switch to the TextExpander touch app, where the user fills out field values, then a switch back to your app, where the completed text is inserted.

To support fill-in snippets, your app needs to:

1. Provide a URL scheme for fill-in snippet completion via x-callback-url. (Leaving this nil will avoid the fill-in process, %fill% macros in the snippet will be replaced with (field name).)
    1. Set the fillCompletionScheme property of the SMTEDelegateController 
    2. Add the scheme to your app's Info in Xcode under "URL Types" (if not using an existing URL scheme -- see note below)
    3. Implement application:openURL:sourceApplication:annotation: or application:handleOpenURL: in your app delegate, and call the SMTEDelegateController's handleFillCompletionURL: with any URL's that have that scheme (or which meet the criteria as described in the note below)
2. Implement the SMTEFillDelegate protocol to allow the SDK to return first responder status to the correct text item to insert a completed fill-in snippet.
    1. Set the fillDelegate property of the SMTEDelegateController with your SMTEFillDelegate implementing object
	2. Set the fillForAppName property of the SMTEDelegateController with your app's name (eg. "SuperTyper"). This will appear in the fill-in view's title, something like "SuperTyper fill-in: [fill abrv]"

Note that you can use an existing URL scheme as your fillCompletionScheme if you want to. The callback URLs will look like these:

- fillCompletionScheme://x-callback-url/SMTEfilled?textID=[text area ID]&loc=[offset into text]&format=[1|0] 
- the above, with, possibly: &cursorPos=[adjust count]&selLen=[selection range if not empty]
- fillCompletionScheme://x-callback-url/SMTEfillcanceled?textID=[text area ID]&loc=[offset into text]
- fillCompletionScheme://x-callback-url/SMTEerror?textID=[text area ID]&loc=[offset into text]&error-Code=NN&errorMessage=bad+thing+happened

So you can easily examine the URL for the presence of x-callback-url in the URL host and /SMTE as the prefix of the URL path to determine whether or not a given URL is a fill-in callback to your URL scheme.

The main point of the SMTEFillDelegate protocol is that, during the fill-in process, the TEtouch app gets activated. Since your app loses focus temporarily, iOS might unload your app, so to insert the filled-in snippet text at the correct location in your app, you must re-activate the text area and tell TE's SDK . The SDK will insert the fill text at the offset where the snippet was activated.

In most cases, iOS will not unload your app in the short time it takes the user to fill the fields, so your SMTEFillDelegate's implementation of makeIdentifiedTextObjectFirstResponder:fillWasCanceled:cursorPosition: generally may not need to do any work at all (other than returning the appropriate value) in cases where your app has not unloaded.

In case your app does get unloaded, you should save whatever text the user was typing when the fill-in snippet was triggered. Your app probably already does this, but the optional prepareForFillSwitch: method gives your app a chance to save state just before the URL which opens TEtouch is opened, or to return NO to abort the process at the last moment.

The SMTEFillDelegate methods are straightforward for UITextViews, UITextFields, and UISearchBars. You make up some kind of name to identify the object, like "mainTextArea". When your app is re-focused and the filled-in snippet text is ready to be inserted, you only need to provide the appropriate UIKit object and make it become first responder in your implementation of makeIdentifiedTextObjectFirstResponder:fillWasCanceled:cursorPosition.

However, for UIWebViews, things are a bit more complicated, since the UIWebView object alone is not enough to specify where the insertion should occur. In that case, an NSDictionary is used so that it can contain both the UIWebView and an ID or name of the HTML element where the fill-in snippet was triggered.

The example app includes two different implementations of SMTEFillDelegate, and demonstrates how to figure out which of two SMTEDelegateController instances to pass a fill completion callback URL to.

### Testing Notes

- If you use TextExpander for Mac OS X, you should probably disable it when testing in the iPhone Simulator, especially if you use your own snippets, as your abbreviations in the Simulator may conflict with those on Mac OS X.
- If you are running in the iOS/iPhone Simulator, you can expand the <UUID>.zip file in the "2.0" folder on GitHub into your [home]/Library/Application Support/iPhone Simulator/6.1/Applications folder while the simulator is not running, and then the TEtouch app should appear in your simulator. This allows you to create snippets and test fill-in snippets on the simulator.
- You can enable some diagnostic/debug logging in the SDK by calling the handleFillCompletionURL: method with a URL like this: [anyScheme]://x-callback-url/SMTEsetlog?log=[off|on|detailed] The log setting resets to off when your app launches (when the SDK library is loaded).
- If expansion is enabled, you can type the "virtual" snippet abbreviation "SmileTE.status" to see a summary of what snippets data, if any, has been loaded.

### Support

Smile offers no promise of support for the TextExpander framework. If you have questions, please address them via email to textexpander-touch@smilesoftware.com. As time and resources permit, we will attempt to answer such questions. Of course, if you are willing to add TextExpander support to your app, it is in our best interest to endeavor to support you.

Stay informed about new versions of the TextExpander framework on this announcement-only Google Group: [https://groups.google.com/forum/#!forum/tetouch-sdk](https://groups.google.com/forum/#!forum/tetouch-sdk)

### License Agreement

The TextExpander framework is Copyright © 2009-2014 SmileOnMyMac, LLC dba Smile, and is supplied "AS IS" and without warranty. SmileOnMyMac, LLC disclaims all warranties, expressed or implied, including, without limitation the warranties of merchantability and of fitness for any purpose. SmileOnMyMac assumes no liability for direct, indirect, incidental, special, exemplary, or consequential damages, which may result from the use of the TextExpander framework, even if advised of the possibility of such damage.

Permission is hereby granted to use, copy, and distribute this library, without fee, subject to the following restrictions:

1. The origin of this library must not be misrepresented
2. Apps which use this library must indicate "Supports TextExpander touch snippet expansion" in their feature set or product description
3. Apps which use this library must indicate "Contains TextExpander framework, Copyright © 2009-2013 SmileOnMyMac, LLC dba Smile. TextExpander is a registered trademark of Smile" in their about box and the paragraph above in their license agreement. It is acceptable to link to the license agreement text posted on the app developer's website if that is more appropriate for a given app.

If your app has special needs with respect to the above restrictions, please address them, preferably with specific suggestions, via email to [textexpander-touch@smilesoftware.com](mailto:textexpander-touch@smilesoftware.com). Perhaps we can find a mutually agreeable solution.

### Default Abbreviations & Snippets

**aaddr:**
123 Market Street
San Francisco, CA

**ddate:**
(day: no leading zero) (month: name) (year: 4 digits)

**sig1:**
Cheers,

Jane Smith
Senior Vice President
Acme, Inc.

**sig2:**
Yours sincerely,

Jane Smith
PTA President
Cupertino Elementary School

**sig3:** (formatted text sample)
Cheers,
Jane Smith
Senior Vice President
Acme, Inc.

**sms1:**
I'm running late. Be there soon.

**sms2:**
Traffic is terrible. I'll be late. Sorry.

**sms3:**
I forgot all about our appointment. Can we reschedule?

**ttel:**
415-555-1212

**tyvm:**
Thank you very much!

**dnthx:**  (fill-in example)
Dear %filltext:name=person name:width:25%,

Thank you for your generous donation of $%filltext:name=amount:width:4%. We greatly appreciate your help, and will use the funds for %fillpopup:name=popup 4:default=our educational program:our health clinic:general purposes%.

Since we are a non-profit organization, your donation of $%filltext:name=amount:width:4% should be tax-deductible.

Thank you,


### Release Notes

**2.3.1 (2013-12-21)**

- Fixes crash in iOS 5 if any formatted snippets are found on load
- Snippet loading moved to async queue if triggered by `textThingShouldBeginEditing:` or `webViewDidFinishLoad:` (for users with multi-Megabyte settings, loading can take several seconds)
- Adds `expansionStatusForceLoad:snippetCount:loadDate:error:` to tell snippets status and/or force snippet loading
- Fixes bug where abbreviations containing '/' or '.' characters would not expand in UIWebView
- Stop falsely giving "Settings indicate snippets have never been imported" log message
- Won't make the x-callback-url openURL call if no getSnippetsScheme has been set (TEtouch 2.3.1 handles bad URLs better as well)

**2.3 (2013-11-25)**

- Adds x-callback-url to acquire and update snippet data
- Removes use of Reminders to store and retrieve snippet data
- Improves support for handling abbreviations entered via input methods / marked text
- If "SmileTE.status" is typed, it expands like a snippet with text that tells whether or not shared snippets were loaded, and maybe an error message
- Steps to transition from the pre-2.3 SDK:
    1. Remove the EventKit framework from your project unless you use it for something other than TextExpander
    2. Remove or edit the NSRemindersUsageDescription in your Info.plist
    3. Remove calls to -[SMTEDelegateController willEnterForeground]
    4. If you've implemented fill-ins, search and replace fillForAppName with clientAppName
    5. Remove any code checking for access to Reminders unless your app uses Reminders for other purposes
	6. Follow the instructions under Acquiring / Updating Snippet Data above

**2.2.1 (2013-09-27)**

- Resolves crash on arm64 found when testing on iPhone 5S

**2.2 (2013-09-25)**

- Respects settings modification date and so reduces reloading and never reloads when expanding a fill-in snippet
- Positions properly when HTML tags in a plain text snippet are consumed by a UIWebView
- Runs line ending related workarounds only when iOS 6 code is running on iOS 7, as those issues appear to be fixed when running iOS 7 code
- In concert with TextExpander touch 2.2, resolves possible problem with sharing snippets when running with a non-Gregorian calendar
- No longer includes SGDeviceHelper in the SDK, which also avoids namespace collision
- Updates reminder checking mechanism in sample app

**2.1 (2013-09-10)**

- Stores snippets in a completed reminder using EventKit
- Your app must now link against EventKit
- Adds +[SMTEDelegateController setAllowRemindersAccessRequest:] so that you can let TextExpander request reminders access or not as you wish
- Updates description of +[SMTEDelegateController snippetsAreShared] as it performs differently now
- Fixes numerous WebKit-related issues when running on iOS 7
- Updates non-expansion character entry to use [UITextInput replaceRange:withText:] instead of setText or setAttributedText so as not to disturb the undo stack
- Adds some Reminders-related code to the sample project
- Adds workaround for UITextView drawing update issue to sample project

**2.0.1 (2013-05-31)**

- Fixes a problem in the 2.0 release where Ignore Case set to ON was ignored on initial SDK snippet load. Snippets would expand only in a case-sensitive fashion until switching to TEtouch and causing Shared Snippets to be updated, thus re-loading the snippets with proper case insensitivity.
- Fixes problem where fill snippets embedded in other snippets did not work.
- Fixes a crash expanding in UITextViews where allowsEditingTextAttributes==YES caused by [UITextView.text length] being longer than [UITextView.attributedText length] (Thanks, Apple! And note that ranges passed to textView:shouldChangeTextInRange:replacementText: can be beyond the end of the attributedText length.)
- If your UITextView or UITextField implements these two methods:
   -(NSAttributedString\*)textExpanderAttributedString;
   -(void)textExpanderSetAttributedString: (NSAttributedString\*)newText;
TextExpander will use prefer to use those instead of attributedText/setAttributedText:.
- Previous-to-2.0.1 versions of TEtouch re-wrote Shared Snippets every time the TEtouch app lost focus. This meant that willEnterForeground reloaded the snippets when your app re-gained focus during fill-in snippet app-switching. 2.0.1 makes this more efficient.

**2.0 (2013-05-15)**

- Adds support for fill-in snippets, if client app implements the SMTEFillDelegate protocol and provides a URL scheme.
- Adds support for formatted text snippets.
- Adds expandPlainTextOnly which defaults to NO and is respected in the expansion/delegate methods
- Adds - (NSAttributedString\*)attributedStringByExpandingAbbreviations:(NSAttributedString\*)inString;
- Cursor position macro (%|) now works in UITextField and HTML (Previously only worked in UITextView. Impossible in UISearchBar.)
- Adds support for selection range macro (ie. %| select this text %\ )
- Fixes problem where cursor would jump to start of a UITextField after an expansion
- Fixes failure to expand immediately after Cut/Delete of a selection range or immediately after a previous expansion
- stringByExpandingAbbreviations: now returns an autoreleased string (previously returned a retained string)
- Fixes problem where snippetsAreShared could incorrectly return YES when TEtouch has been installed but never launched
- sample project includes two different implementations of fill-in support
- sample project includes a simplistic input accessory view for the iPad's UITextView showing how to insert text in a way that the SDK understands as typing
- requires iOS 5.1 or later/Xcode 4.3 or later (use SDK version 1.2.3 for iOS 3.1/Xcode 3.2.3)

**1.2.3 (2012-10-14)**

- Adds support for contentEditable / designMode in UIWebViews
- UITextView delegate methods can handle attributed strings in UITextViews on iOS 6
- UITextField delegate methods can handle attributed strings in UITextFields on iOS 6
- Adds read only property isAttemptingToExpandText which can be tested within the nextDelegate
- Adds stringByExpandingAbbreviations method for DIY expansion
- CHANGE: UITextView / UITextField delegate methods can handle NSAttributedStrings for pre-iOS 6 UITextViews, but only if the UITextView / UITextField subclass implements textExpanderAttributedString and setTextExpanderAttributedString: -- this ensures TextExpander does not attempt to call attributedString or setAttributedString:, which may be private methods of the UITextView / UITextField class
- Removes support for armv6 (use 1.2.2 SDK if you must continue to offer armv6 support)

**1.2.2 (2012-09-13)**

- Adds armv7s architecture to support iPhone 5

**1.2.1 (2012-08-28)**

- Fixes case where if the first letter typed in UISearchBar begins an abbreviation, the snippet does not expand. (Thanks Tim Ekl.)

**1.2 (2012-06-30)**

- UITextView delegate methods can handle NSAttributedStrings so that TextExpander can work with EGOTextView
- Adds support for old-style time zone formatting: %z and %Z
- Repackaged TextExpander as universal framework to simplify building
- Updates company name in Read Me file, as we've been dba Smile for quite some time

**1.1.7 (2011-01-25)**

- Adds class method to disable expansion + [SMTEDelegateController setExpansionEnabled:]
- Fixes problem where use in a web form field would disable the Go button for submit

**1.1.6 (2010-08-07)**

- Adds support for multitasking apps to inform TextExpander touch when returning to the foreground [SMTEDelegateController willEnterForeground:]
- Adds support for TextExpander touch functionality in UISearchBar; see "tetest" example app
- Fixes date format problem with literals between the formatting and added support for explicit %date:%
- Only disable and re-enable scroll if it's already actually enabled. (Thanks Kent Sutherland.)
- Fixes copy/paste problem which caused incorrect backspace handling for UITextFields. (Thanks David Reed.)

NOTE: The iPhone Simulator shipped with Xcode 3.2.3 has a different ABI than previous releases. It MUST link against the libteEngine.a in the Simulator4 folder. We've removed the Simulator folder from this build to avoid confusion. We have confirmed with Apple that the ABI change affects only the Simuatlor and that static libraries compiled for iOS 3 will run properly when linked with iOS 4 targets.

**1.1.5 (2010-05-27)**

- Added preliminary support for TextExpander touch functionality in UIWebViews; see "tetest" example app; feedback welcome
- Added resetKeyLog method to SMTEDelegateController in case you need to clear the key log
- Added support for building for the iPhone OS 4 (beta) Simulator target
- Fixed method forwarding to the nextDelegate such that, for example, textFieldDidBecomeFirstResponder: sent to a UITextField delegate inside a UITableViewCell is handled properly
- Clear key log when the clear button is tapped on a UITextField (so that an immediately typed abbreviation expands properly)

**1.1.4 (2010-03-23)**

- SMTEDelegateController no longer retains nextDelegate
- nextDelegate now receives and responds to shouldChange… delegate methods reflecting what TextExpander is about to do (before, no message was sent)
- Added optional (on by default) support for Undo
- Updated SMTEDelegateController.h header to show nextDelegate and provideUndoSupport properties
- Added +[SMTEDelegateController isTextExpanderTouchInstalled], which returns YES when TextExpander touch is installed on the device
- Added +[SMTEDelegateController snippetsAreShared], which returns YES when "Share Snippets" is enabled in TextExpander touch
- Removed dependency on AddressBook framework (was there for compatibility with TextExpander 1.0)
- Added iPad target to sample project
- Removed .svn folders from teTouchSDK folder

**1.1.3 (2010-02-08)**

- Fix crashing bug when %| is the first character
- Fix crashing bug when pasted text length is less than replacement length
- Expand for paste-and-replace as we do for paste

**1.1.2 (2009-11-06)**

- Add support for absolute cursor positioning (%|)
- Fix crash when large amounts of content is pasted into TextExpander delegate UITextViews
- Fix subsequent expansions when expand immediately is off (space was not being restored to the key log when there was no snippet match)
- Fix escaping of % (%% was not expanding to % as it should)

**1.1.1.1 (2009-10-13)**

- Fix handling of case where optional UITextViewDelegate methods aren't called (as when a developer subclasses UITextView and does not call them)
- Added step 12 above re: linking with AddressBook and AudioToolkit frameworks

**1.1.1 (2009-10-05)**

- Respects "Play Sound" preference
- Added step 11 above to explain linking against the TextExpander engine

**1.1 (2009-09-10)**

- Favors UIPasteboard to read snippet data when available
	(TextExpander touch 1.1 will write snippet data there instead of to Address Book)
- Respects TextExpander touch settings for "Ignore Case" and "Expand Immediately" as of TextExpander touch 1.1
- NOTE: Please be sure to do clean build with updated libraries
- NOTE: This library will work with TextExpander 1.0.1 / Address Book. It will work better with 1.1 / UIPasteboard.

**1.0.2 (2009-08-31)**

- Mea culpa update -- zip file for 1.0.1 was incorrect

**1.0.1 (2009-08-30)**

- Updated teTouchSDK sample to use build setting conditions so that you need not manually rename the libteEngine.a library 
- Updated libteEngine so that SMTEDelegateController conforms to the UIScrollView protocol (and passes on delegate method calls to nextDelegate)
- Updated libteEngine so that if the nextDelegate responds to a method SMTEDelegateController will call through to nextDelegate (in an attempt to future-proof the delegate protocols)
- Fixed bug so that if the user pastes a defined abbreviation it works (as of 1.0, it either crashed or got the replacement cursor positioning wrong; this fix will be in TextExpander touch 1.1; you get it early)

**1.0 (2009-08-24)**

- First public release.

[^1]: The framework is unsigned. It will inherit your signature when you build an app linking it.
