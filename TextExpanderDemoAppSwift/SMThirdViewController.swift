//
//  SMThirdViewController.swift
//  TextExpanderDemoAppSwift
//
//  Created by Greg Scown on 7/24/16.
//  Copyright © 2016 SmileOnMyMac, LLC. All rights reserved.
//

import UIKit
import WebKit
import TextExpander

class SMThirdViewController: UIViewController, SMTextExpanderViewController, SMTEFillDelegate, UIWebViewDelegate {
    @IBOutlet weak var webView: UIWebView!
    var textExpander: SMTEDelegateController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textExpander = SMTEDelegateController()
        self.textExpander?.clientAppName = "TextExpanderDemoApp"
        self.textExpander?.fillCompletionScheme = "textexpanderdemoapp-fill-xc"
        self.textExpander?.fillDelegate = self
        self.textExpander?.appGroupIdentifier = "group.com.smileonmymac.textexpander.demoapp"
        // !!! You must change this
        self.webView.delegate = self.textExpander
        self.textExpander?.nextDelegate = self
        let html: String = "<body id=\"myWebView\">TE Test<div><br></div><table><tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr></table><div>Before starting with a snippet</div><div><br></div></body>"
        self.webView.loadHTMLString(html, baseURL: NSURL(string: "/")!)
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
    func identifierForTextArea(uiTextObject: AnyObject) -> String {
        var result: String? = nil
        if (uiTextObject is NSDictionary) {
            let wv: UIWebView = (uiTextObject[SMTEkWebView] as! UIWebView)
            if self.webView == wv {
                var fieldInfo: String?
                fieldInfo = uiTextObject[SMTEkElementID] as? String
                if fieldInfo != nil {
                    result = "webview_ID:\(fieldInfo!)"
                } else {
                    fieldInfo = uiTextObject[SMTEkElementName] as? String
                    result = "webview_Name:\(fieldInfo!)"
                }
                
                if result == nil {
                    result = "myWebView"
                }
            }
        }
        return result!
    }
    
/* Usually called milliseconds after identifierForTextArea:, SMTEDelegateController is
 * about to call [[UIApplication sharedApplication] openURL: "tetouch-xc: *x-callback-url/fillin?..."]
 * In other words, the TEtouch is about to be activated. Your app should save state
 * and make any other preparations.
 *
 * Return false to cancel the process.
 */
    func prepareForFillSwitch(textIdentifier: String!) -> Bool {
        // At this point the app should save state since TextExpander touch is about
        // to activate.
        // It especially needs to save the contents of the textview/textfield!
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
        var srchRange: Range? = textIdentifier.rangeOfString("webview_")
        if (srchRange != nil) {
            self.webView.becomeFirstResponder()
            // TE should take care of moving focus to the identified field, but we need to build
            // a dictionary to identify the field
            srchRange = textIdentifier.rangeOfString("webview_ID:")
            if (srchRange != nil) {
                return [
                    SMTEkWebView : self.webView,
                    SMTEkElementID : textIdentifier.substringFromIndex((srchRange?.endIndex)!)
                ]
            }
            srchRange = textIdentifier.rangeOfString("webview_Name:")
            if (srchRange != nil) {
                return [
                    SMTEkWebView : self.webView,
                    SMTEkElementName : textIdentifier.substringFromIndex((srchRange?.endIndex)!)
                ]
            }
            return nil
        }
        if ("myWebView" == textIdentifier) {
            self.webView.becomeFirstResponder()
            return [
                SMTEkWebView : self.webView,
                SMTEkElementID : "myWebView"
            ]
        }
        return nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        print("webViewDidStartLoad")
    }
    
    func webViewDidFinishLoad(inWebView: UIWebView) {
        inWebView.stringByEvaluatingJavaScriptFromString("document.body.contentEditable ='true'; document.designMode='on';")!
        print("webViewDidFinishLoad")
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        print("webView:didFailLoadWithError: \(error!)")
    }
}
