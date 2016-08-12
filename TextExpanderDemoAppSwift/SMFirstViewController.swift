//
//  FirstViewController.swift
//  TextExpanderDemoAppSwift
//
//  Created by Greg Scown on 7/23/16.
//  Copyright © 2016 SmileOnMyMac, LLC. All rights reserved.
//

import UIKit
import TextExpander

class SMFirstViewController: UIViewController, SMTextExpanderViewController, SMTEFillDelegate {
    @IBOutlet weak var textView: UITextView?
    @IBOutlet weak var textField: UITextField?
    @IBOutlet weak var searchBar: UISearchBar?

    var textExpander : SMTEDelegateController?
    var snippetExpanded: Bool = false
    var tapRecognizer: UITapGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupKeyboardDismissal()

        self.textExpander = SMTEDelegateController()
        self.searchBar!.delegate = self.textExpander
        self.textField!.delegate = self.textExpander
        self.textView!.delegate = self.textExpander
        self.textExpander!.nextDelegate = self

        self.textExpander!.clientAppName = "TextExpanderDemoApp"
        self.textExpander!.fillCompletionScheme = "textexpanderdemoapp-fill-xc"
        self.textExpander!.fillDelegate = self
        self.textExpander!.appGroupIdentifier = "group.com.smileonmymac.textexpander.demoapp"; // !!! You must change this
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
    func identifierForTextArea(uiTextObject: AnyObject!) -> String? {
        if (self.textView! === uiTextObject) {
            return "myTextView";
        }
        if (self.textField! === uiTextObject) {
            return "myTextField";
        }
        if (self.searchBar! === uiTextObject) {
            return "mySearchBar";
        }
        return nil;
    }

/* Usually called milliseconds after identifierForTextArea:, SMTEDelegateController is
 * about to call [[UIApplication sharedApplication] openURL: "tetouch-xc: *x-callback-url/fillin?..."]
 * In other words, the TEtouch is about to be activated. Your app should save state
 * and make any other preparations.
 *
 * Return NO to cancel the process.
 */
    func prepareForFillSwitch(textIdentifier: String!) -> Bool {
        return true;
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
    func makeIdentifiedTextObjectFirstResponder(textIdentifier: String!, fillWasCanceled userCanceledFill: Bool, cursorPosition ioInsertionPointLocation: UnsafeMutablePointer<Int>) -> AnyObject! {
        self.snippetExpanded = true;
        if ("myTextView" == textIdentifier) {
            self.textView?.becomeFirstResponder()
            let theLoc = self.textView?.positionFromPosition((self.textView?.beginningOfDocument)!, offset: ioInsertionPointLocation.memory);
            if ((theLoc) != nil) {
                self.textView?.selectedTextRange = self.textView?.textRangeFromPosition(theLoc!, toPosition: theLoc!);
            }
            return self.textView;
        }
        if ("myTextField" == textIdentifier) {
            self.textField?.becomeFirstResponder();
            let theLoc = self.textView?.positionFromPosition((self.textView?.beginningOfDocument)!, offset: ioInsertionPointLocation.memory);
            if ((theLoc) != nil) {
                self.textField?.selectedTextRange = self.textField?.textRangeFromPosition(theLoc!, toPosition: theLoc!);
            }
            return self.textField
        }
        if ("mySearchBar" == textIdentifier) {
            self.searchBar?.becomeFirstResponder()
            // Note: UISearchBar does not support cursor positioning.
            // Since we don't save search bar text as part of our state, if our app was unloaded while TE was
            // presenting the fill-in window, the search bar might now be empty to we should return
            // insertionPointLocation of 0.
            let searchTextLen = ((self.searchBar?.text)! as NSString).length
            if (searchTextLen < ioInsertionPointLocation.memory) {
                ioInsertionPointLocation.memory = searchTextLen
            }
            return self.searchBar
        }
        return nil;
    }
    
    func setupKeyboardDismissal() {
        let nc: NSNotificationCenter = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
        self.tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didTapAnywhere))
    }
    
    func keyboardWillShow(note: NSNotification) {
        self.view!.addGestureRecognizer(self.tapRecognizer!)
    }
    
    func keyboardWillHide(note: NSNotification) {
        self.view!.removeGestureRecognizer(self.tapRecognizer!)
    }
    
    func didTapAnywhere(recognizer: UITapGestureRecognizer) {
        recognizer.view!.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
// The following are the UITextViewDelegate methods; they simply write to the console log for demonstration purposes
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        print("nextDelegate textViewShouldBeginEditing")
        return true
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        print("nextDelegate textViewShouldEndEditing")
        return true
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        print("nextDelegate textViewDidBeginEditing")
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        print("nextDelegate textViewDidEndEditing")
    }
    
    func textView(aTextView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if self.textExpander!.isAttemptingToExpandText {
            self.snippetExpanded = true
        }
        print("nextDelegate textView:shouldChangeTextInRange: \(NSStringFromRange(range)) originalText: \(aTextView.text) replacementText: \(text)")
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
        if self.snippetExpanded {
            self.snippetExpanded = false
        }
        print("nextDelegate textViewDidChange")
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        print("nextDelegate textViewDidChangeSelection")
    }
    
// The following are the UITextFieldDelegate methods; they simply write to the console log for demonstration purposes
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        print("nextDelegate textFieldShouldBeginEditing")
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        print("nextDelegate textFieldDidBeginEditing")
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        print("nextDelegate textFieldShouldEndEditing")
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        print("nextDelegate textFieldDidEndEditing")
    }
    
    func textField(aTextField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        print("nextDelegate textField:shouldChangeCharactersInRange: \(NSStringFromRange(range)) originalText: \(aTextField.text!) replacementText: \(string)")
        return true
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        print("nextDelegate textFieldShouldClear")
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        print("nextDelegate textFieldShouldReturn")
        return true
    }

// The following are the UISearchBarDelegate methods; they simply write to the console log for demonstration purposes
    
    func searchBarCancelButtonClicked(inSearchBar: UISearchBar) {
        print("searchBarCancelButtonClicked: \(inSearchBar)")
    }
}

