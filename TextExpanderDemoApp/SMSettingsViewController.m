//
//  SMSettingsViewController.m
//  TextExpanderDemoApp
//
//  Created by Greg Scown on 11/23/13.
//  Copyright (c) 2013 Greg Scown. All rights reserved.
//

#import "SMSettingsViewController.h"

typedef enum {
    SMTESettingsViewBlankCellIndex = 0,
    SMTESettingsViewToggleIndex = 1,
    SMTESettingsViewUpdateIndex = 2
} SMTESettingsViewCellIndex;

@implementation SMSettingsViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateCells];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self updateCells];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self updateCells];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [self updateCells];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (void)updateCells {
    BOOL textExpanderIsInstalled = [SMTEDelegateController isTextExpanderTouchInstalled];
    if (self.blankCell == nil) {
        self.blankCell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault
                                                             reuseIdentifier:@"blankCell"];
        self.blankCell.userInteractionEnabled = NO;
        self.blankCell.textLabel.enabled = NO;
        self.blankCell.detailTextLabel.enabled = NO;

    }
    if (self.textExpanderToggleCell == nil) {
        self.textExpanderToggleCell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier:@"textExpanderToggleCell"];
        self.textExpanderToggleCell.textLabel.text = @"Use TextExpander";
        self.textExpanderToggleCell.selectionStyle = UITableViewCellSelectionStyleNone;
		CGRect frame = CGRectMake(220.0, 6, 94.0, 27.0);
        self.textExpanderToggle = [[UISwitch alloc] initWithFrame:frame];
		[self.textExpanderToggle addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
        [self.textExpanderToggleCell.contentView addSubview:self.textExpanderToggle];
    }
    if (self.textExpanderUpdateCell == nil) {
        self.textExpanderUpdateCell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier:@"textExpanderUpdateCell"];
        self.textExpanderUpdateCell.selectionStyle = UITableViewCellSelectionStyleBlue;
        if (textExpanderIsInstalled) {
            self.textExpanderUpdateCell.textLabel.text = @"Update Snippets";
        } else {
            self.textExpanderUpdateCell.textLabel.text = @"Get TextExpander";
        }
    }    
    BOOL useTextExpander = [[NSUserDefaults standardUserDefaults] boolForKey:SMTEExpansionEnabled];
    if (![SMTEDelegateController snippetsAreShared:nil]) {
        NSLog(@"Might want to encourage user to update snippets");
    }
    self.textExpanderToggle.on = textExpanderIsInstalled && useTextExpander;
    self.textExpanderToggle.enabled = textExpanderIsInstalled;
    self.textExpanderToggleCell.userInteractionEnabled = textExpanderIsInstalled;
    self.textExpanderToggleCell.textLabel.enabled = textExpanderIsInstalled;
    self.textExpanderToggleCell.detailTextLabel.enabled = textExpanderIsInstalled;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *result = nil;
    switch ([indexPath row]) {
        case SMTESettingsViewBlankCellIndex:
            result = self.blankCell;
            break;
        case SMTESettingsViewToggleIndex:
            result = self.textExpanderToggleCell;
            break;
        case SMTESettingsViewUpdateIndex:
            result = self.textExpanderUpdateCell;
            break;
        default:
            break;
    }
    return result;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath row] == SMTESettingsViewUpdateIndex) {
        if ([SMTEDelegateController isTextExpanderTouchInstalled]) {
            if (self.textExpander == nil) {
                // Lazy load of TextExpander
                self.textExpander = [[SMTEDelegateController alloc] init];
                self.textExpander.clientAppName = @"TextExpanderDemoApp";
                self.textExpander.getSnippetsScheme = @"textexpanderdemoapp-get-snippets-xc";
            }
            [self.textExpander getSnippets];
        } else {
            // Note: This only works on the device, not in the Simulator, as the Simulator does
            // not include the App Store app
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://smilesoftware.com/cgi-bin/redirect.pl?product=tetouch&cmd=itunes"]];
        }
        self.textExpanderUpdateCell.selected = NO;
    }
}

- (void)switchAction:(id)sender {
    if (sender == self.textExpanderToggle) {
        BOOL newIsEnabled = [sender isOn];
        [SMTEDelegateController setExpansionEnabled:newIsEnabled];
		[[NSUserDefaults standardUserDefaults] setBool: newIsEnabled forKey: SMTEExpansionEnabled];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
