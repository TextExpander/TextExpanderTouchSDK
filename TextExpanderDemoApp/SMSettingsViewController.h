//
//  SMSettingsViewController.h
//  TextExpanderDemoApp
//
//  Created by Greg Scown on 11/23/13.
//  Copyright (c) 2013 Greg Scown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TextExpander/SMTEDelegateController.h>
#import "SMAppDelegate.h"

@interface SMSettingsViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableViewCell *blankCell;
@property (strong, nonatomic) UITableViewCell *textExpanderToggleCell;
@property (strong, nonatomic) UITableViewCell *textExpanderUpdateCell;
@property (strong, nonatomic) UISwitch *textExpanderToggle;

@property (strong, nonatomic) SMTEDelegateController *textExpander;

@end
