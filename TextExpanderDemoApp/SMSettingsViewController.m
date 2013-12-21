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
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self updateCells];
		[self.tableView reloadData];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self updateCells];
		[self.tableView reloadData];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [self updateCells];
	[self.tableView reloadData];
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
        self.textExpanderUpdateCell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier:@"textExpanderUpdateCell"];
        self.textExpanderUpdateCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }    
    BOOL useTextExpander = [[NSUserDefaults standardUserDefaults] boolForKey:SMTEExpansionEnabled];
    self.textExpanderToggle.on = textExpanderIsInstalled && useTextExpander;
    self.textExpanderToggle.enabled = textExpanderIsInstalled;
    self.textExpanderToggleCell.userInteractionEnabled = textExpanderIsInstalled;
    self.textExpanderToggleCell.textLabel.enabled = textExpanderIsInstalled;
    self.textExpanderToggleCell.detailTextLabel.enabled = textExpanderIsInstalled;
	
	if (textExpanderIsInstalled && useTextExpander) {
		self.textExpanderUpdateCell.textLabel.enabled = YES;
		self.textExpanderUpdateCell.detailTextLabel.enabled = YES;
		NSDate *modDate;
		NSError *loadErr;
		NSUInteger snipCount;
		BOOL haveSettings = [SMTEDelegateController expansionStatusForceLoad: NO snippetCount: &snipCount loadDate: &modDate error: &loadErr];
		if (haveSettings) {
			self.textExpanderUpdateCell.textLabel.text = @"Update Snippets";
			if (loadErr != nil) {
				self.textExpanderUpdateCell.detailTextLabel.text = [NSString stringWithFormat: @"Error: %@", [loadErr description]];
			} else if (modDate != nil) {		// mod date present means that snippet data is already stored
				NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
				[formatter setDateStyle:NSDateFormatterShortStyle];
				[formatter setTimeStyle: NSDateFormatterShortStyle];
				NSString *lastDateStr = [formatter stringFromDate: modDate];
				if (snipCount > 0) {	// snippets means the snippet data has been loaded
					self.textExpanderUpdateCell.detailTextLabel.text = [NSString stringWithFormat: @"%ld snippets modified: %@", (long)snipCount, lastDateStr];
				}
				else {		// snippet data is present, but has not been loaded yet
					self.textExpanderUpdateCell.detailTextLabel.text = [NSString stringWithFormat: @"Modified: %@", lastDateStr];
				}
			}
			else	// shouldn't get to this case except in weird error scenario
				self.textExpanderUpdateCell.detailTextLabel.text = nil;
		} else if (loadErr != nil) {
			self.textExpanderUpdateCell.textLabel.text = @"Fetch Snippets";
			self.textExpanderUpdateCell.detailTextLabel.text = [NSString stringWithFormat: @"Error: %@", [loadErr description]];
		} else {
			self.textExpanderUpdateCell.textLabel.text = @"Fetch Snippets";
			self.textExpanderUpdateCell.detailTextLabel.text = @"(no snippets loaded yet)";
		}
	} else if (textExpanderIsInstalled) {
		self.textExpanderUpdateCell.textLabel.enabled = NO;
		self.textExpanderUpdateCell.detailTextLabel.enabled = NO;
		self.textExpanderUpdateCell.textLabel.text = @"Expansion disabled";
		self.textExpanderUpdateCell.detailTextLabel.text = nil;
	} else {
		self.textExpanderUpdateCell.textLabel.enabled = YES;
		self.textExpanderUpdateCell.detailTextLabel.enabled = NO;
		self.textExpanderUpdateCell.textLabel.text = @"Get TextExpander";
		self.textExpanderUpdateCell.detailTextLabel.text = nil;
	}
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
		BOOL useTextExpander = [[NSUserDefaults standardUserDefaults] boolForKey:SMTEExpansionEnabled];
		if (!useTextExpander)
			return;		// ignore taps if expansion is disabled
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
		// You can wipe out any stored snippet data by doing this:
//		if (!newIsEnabled) {
//			[SMTEDelegateController clearSharedSnippets];
//		}
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
