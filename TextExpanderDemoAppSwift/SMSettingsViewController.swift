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
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateCells()
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil, using: {(note: Notification) -> Void in
            self.updateCells()
            self.tableView.reloadData()
        })
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil, using: {(note: Notification) -> Void in
            self.updateCells()
            self.tableView.reloadData()
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.updateCells()
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func updateCells() {
        let textExpanderIsInstalled: Bool = SMTEDelegateController.isTextExpanderTouchInstalled()
        if self.blankCell == nil {
            self.blankCell = UITableViewCell(style: .default, reuseIdentifier: "blankCell")
            self.blankCell!.isUserInteractionEnabled = false
            self.blankCell!.textLabel?.isEnabled = false
            self.blankCell!.detailTextLabel?.isEnabled = false
        }
        if self.textExpanderToggleCell == nil {
            self.textExpanderToggleCell = UITableViewCell(style: .default, reuseIdentifier: "textExpanderToggleCell")
            self.textExpanderToggleCell.textLabel?.text = "Use TextExpander"
            self.textExpanderToggleCell.selectionStyle = .none
            let frame: CGRect = CGRect(x: 220.0, y: 6, width: 94.0, height: 27.0)
            self.textExpanderToggle = UISwitch(frame: frame)
            self.textExpanderToggle.addTarget(self, action: #selector(self.switchAction), for: .valueChanged)
            self.textExpanderToggleCell.contentView.addSubview(self.textExpanderToggle)
        }
        if self.textExpanderUpdateCell == nil {
            self.textExpanderUpdateCell = UITableViewCell(style: .subtitle, reuseIdentifier: "textExpanderUpdateCell")
            self.textExpanderUpdateCell.selectionStyle = .blue
        }
        let useTextExpander: Bool = UserDefaults.standard.bool(forKey: SMConstants.SMTEExpansionEnabled)
        self.textExpanderToggle.isOn = textExpanderIsInstalled && useTextExpander
        self.textExpanderToggle.isEnabled = textExpanderIsInstalled
        self.textExpanderToggleCell.isUserInteractionEnabled = textExpanderIsInstalled
        self.textExpanderToggleCell.textLabel?.isEnabled = textExpanderIsInstalled
        self.textExpanderToggleCell.detailTextLabel?.isEnabled = textExpanderIsInstalled
        if textExpanderIsInstalled && useTextExpander {
            self.textExpanderUpdateCell.textLabel?.isEnabled = true
            self.textExpanderUpdateCell.detailTextLabel?.isEnabled = true
            var modDate : NSDate? = nil
            var snipCount : UInt = 0
            var haveSettings: Bool = true
            var loadErr: NSError? = nil
            do {
                try SMTEDelegateController.expansionStatusForceLoad(false, snippetCount: &snipCount, load: &modDate)
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
                    let formatter: DateFormatter = DateFormatter()
                    formatter.dateStyle = .short
                    formatter.timeStyle = .short
                    let lastDateStr: String = formatter.string(from: modDate! as Date)
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
            self.textExpanderUpdateCell.textLabel?.isEnabled = false
            self.textExpanderUpdateCell.detailTextLabel?.isEnabled = false
            self.textExpanderUpdateCell.textLabel?.text = "Expansion disabled"
            self.textExpanderUpdateCell.detailTextLabel?.text = nil
        }
        else {
            self.textExpanderUpdateCell.textLabel?.isEnabled = true
            self.textExpanderUpdateCell.detailTextLabel?.isEnabled = false
            self.textExpanderUpdateCell.textLabel?.text = "Get TextExpander"
            self.textExpanderUpdateCell.detailTextLabel?.text = nil
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == SMTESettingsViewCellIndex.SMTESettingsViewUpdateIndex.rawValue {
            let useTextExpander: Bool = UserDefaults.standard.bool(forKey: SMConstants.SMTEExpansionEnabled)
            if !useTextExpander {
                // Note: This only works on the device, not in the Simulator, as the Simulator does
                // not include the App Store app
                UIApplication.shared.open(NSURL(string: "http://smilesoftware.com/cgi-bin/redirect.pl?product=tetouch&cmd=itunes")! as URL, options: [:], completionHandler: nil);
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
            self.textExpanderUpdateCell.isSelected = false
        }
    }
    
    
    @objc func switchAction(sender: AnyObject) {
        let toggle = sender as! UISwitch
        if toggle == self.textExpanderToggle {
            let newIsEnabled: Bool = toggle.isOn
            SMTEDelegateController.setExpansionEnabled(newIsEnabled)
            UserDefaults.standard.set(newIsEnabled, forKey: SMConstants.SMTEExpansionEnabled)
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
