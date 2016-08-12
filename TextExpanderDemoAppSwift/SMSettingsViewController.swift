//
//  SMSettingsViewController.swift
//  TextExpanderDemoAppSwift
//
//  Created by Greg Scown on 7/24/16.
//  Copyright © 2016 SmileOnMyMac, LLC. All rights reserved.
//

import UIKit
import TextExpander

class SMSettingsViewController: UITableViewController, SMTextExpanderViewController {
    var blankCell: UITableViewCell?
    var textExpanderToggleCell: UITableViewCell!
    var textExpanderUpdateCell: UITableViewCell!
    var textExpanderToggle: UISwitch!
    var textExpander: SMTEDelegateController?

    enum SMTESettingsViewCellIndex : Int {
        case SMTESettingsViewBlankCellIndex = 0
        case SMTESettingsViewToggleIndex = 1
        case SMTESettingsViewUpdateIndex = 2
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateCells()
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: nil, usingBlock: {(note: NSNotification) -> Void in
            self.updateCells()
            self.tableView.reloadData()
        })
        NSNotificationCenter.defaultCenter().addObserverForName(NSUserDefaultsDidChangeNotification, object: nil, queue: nil, usingBlock: {(note: NSNotification) -> Void in
            self.updateCells()
            self.tableView.reloadData()
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        self.updateCells()
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func updateCells() {
        let textExpanderIsInstalled: Bool = SMTEDelegateController.isTextExpanderTouchInstalled()
        if self.blankCell == nil {
            self.blankCell = UITableViewCell(style: .Default, reuseIdentifier: "blankCell")
            self.blankCell!.userInteractionEnabled = false
            self.blankCell!.textLabel?.enabled = false
            self.blankCell!.detailTextLabel?.enabled = false
        }
        if self.textExpanderToggleCell == nil {
            self.textExpanderToggleCell = UITableViewCell(style: .Default, reuseIdentifier: "textExpanderToggleCell")
            self.textExpanderToggleCell.textLabel?.text = "Use TextExpander"
            self.textExpanderToggleCell.selectionStyle = .None
            let frame: CGRect = CGRectMake(220.0, 6, 94.0, 27.0)
            self.textExpanderToggle = UISwitch(frame: frame)
            self.textExpanderToggle.addTarget(self, action: #selector(self.switchAction), forControlEvents: .ValueChanged)
            self.textExpanderToggleCell.contentView.addSubview(self.textExpanderToggle)
        }
        if self.textExpanderUpdateCell == nil {
            self.textExpanderUpdateCell = UITableViewCell(style: .Subtitle, reuseIdentifier: "textExpanderUpdateCell")
            self.textExpanderUpdateCell.selectionStyle = .Blue
        }
        let useTextExpander: Bool = NSUserDefaults.standardUserDefaults().boolForKey(SMConstants.SMTEExpansionEnabled)
        self.textExpanderToggle.on = textExpanderIsInstalled && useTextExpander
        self.textExpanderToggle.enabled = textExpanderIsInstalled
        self.textExpanderToggleCell.userInteractionEnabled = textExpanderIsInstalled
        self.textExpanderToggleCell.textLabel?.enabled = textExpanderIsInstalled
        self.textExpanderToggleCell.detailTextLabel?.enabled = textExpanderIsInstalled
        if textExpanderIsInstalled && useTextExpander {
            self.textExpanderUpdateCell.textLabel?.enabled = true
            self.textExpanderUpdateCell.detailTextLabel?.enabled = true
            var modDate : NSDate? = nil
            var snipCount : UInt = 0
            var haveSettings: Bool = true
            var loadErr: NSError? = nil
            do {
                try SMTEDelegateController.expansionStatusForceLoad(false, snippetCount: &snipCount, loadDate: &modDate)
                if (modDate == nil && snipCount == 0) {
                    haveSettings = false
                }
            } catch let error as NSError {
                loadErr = error
                self.textExpanderUpdateCell.detailTextLabel!.text = "Error: \(error.description)"
            }
            if haveSettings {
                self.textExpanderUpdateCell.textLabel!.text = "Update Snippets"
                if modDate != nil {
                    // mod date present means that snippet data is already stored
                    let formatter: NSDateFormatter = NSDateFormatter()
                    formatter.dateStyle = .ShortStyle
                    formatter.timeStyle = .ShortStyle
                    let lastDateStr: String = formatter.stringFromDate(modDate!)
                    if snipCount > 0 {
                        // snippets means the snippet data has been loaded
                        self.textExpanderUpdateCell.detailTextLabel!.text = "\(Int(snipCount)) snippets modified: \(lastDateStr)"
                    }
                    else {
                        // snippet data is present, but has not been loaded yet
                        self.textExpanderUpdateCell.detailTextLabel!.text = "Modified: \(lastDateStr)"
                    }
                }
                else {
                    // shouldn't get to this case except in weird error scenario
                    self.textExpanderUpdateCell.detailTextLabel!.text = nil
                }
            } else if loadErr != nil {
                self.textExpanderUpdateCell.textLabel!.text = "Fetch Snippets"
            } else {
                self.textExpanderUpdateCell.textLabel!.text = "Fetch Snippets"
                self.textExpanderUpdateCell.detailTextLabel!.text = "(no snippets loaded yet)"
            }
        }
        else if textExpanderIsInstalled {
            self.textExpanderUpdateCell.textLabel?.enabled = false
            self.textExpanderUpdateCell.detailTextLabel?.enabled = false
            self.textExpanderUpdateCell.textLabel?.text = "Expansion disabled"
            self.textExpanderUpdateCell.detailTextLabel?.text = nil
        }
        else {
            self.textExpanderUpdateCell.textLabel?.enabled = true
            self.textExpanderUpdateCell.detailTextLabel?.enabled = false
            self.textExpanderUpdateCell.textLabel?.text = "Get TextExpander"
            self.textExpanderUpdateCell.detailTextLabel?.text = nil
        }
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var result: UITableViewCell? = nil
        switch indexPath.row {
        case SMTESettingsViewCellIndex.SMTESettingsViewBlankCellIndex.rawValue:
            result = self.blankCell
        case SMTESettingsViewCellIndex.SMTESettingsViewToggleIndex.rawValue:
            result = self.textExpanderToggleCell
        case SMTESettingsViewCellIndex.SMTESettingsViewUpdateIndex.rawValue:
            result = self.textExpanderUpdateCell
        default:
            break
        }
        
        return result!
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == SMTESettingsViewCellIndex.SMTESettingsViewUpdateIndex.rawValue {
            let useTextExpander: Bool = NSUserDefaults.standardUserDefaults().boolForKey(SMConstants.SMTEExpansionEnabled)
            if !useTextExpander {
                // Note: This only works on the device, not in the Simulator, as the Simulator does
                // not include the App Store app
                UIApplication.sharedApplication().openURL(NSURL(string: "http://smilesoftware.com/cgi-bin/redirect.pl?product=tetouch&cmd=itunes")!)
            } else {
                // ignore taps if expansion is disabled
                if SMTEDelegateController.isTextExpanderTouchInstalled() {
                    if self.textExpander == nil {
                        // Lazy load of TextExpander
                        self.textExpander = SMTEDelegateController()
                        self.textExpander?.clientAppName = "TextExpanderDemoApp"
                        self.textExpander?.getSnippetsScheme = "textexpanderdemoapp-get-snippets-xc"
                    }
                    self.textExpander?.getSnippets()
                }
            }
            self.textExpanderUpdateCell.selected = false
        }
    }
    
    
    func switchAction(sender: AnyObject) {
        let toggle = sender as! UISwitch
        if toggle == self.textExpanderToggle {
            let newIsEnabled: Bool = toggle.on
            SMTEDelegateController.setExpansionEnabled(newIsEnabled)
            NSUserDefaults.standardUserDefaults().setBool(newIsEnabled, forKey: SMConstants.SMTEExpansionEnabled)
// You can wipe out any stored snippet data by doing this:
            // if (!newIsEnabled) {
            //    SMTEDelegateController.clearSharedSnippets();
            // }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
