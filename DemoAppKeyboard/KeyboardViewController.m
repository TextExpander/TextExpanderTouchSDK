//
//  KeyboardViewController.m
//  DemoAppKeyboard
//
//  Created by Greg Scown on 8/6/14.
//  Copyright (c) 2014 Greg Scown. All rights reserved.
//

#import "KeyboardViewController.h"
#import <TextExpander/SMTEDelegateController.h>

@interface KeyboardViewController ()
@property (nonatomic, strong) IBOutlet UIView *keyboardView;
@property (nonatomic, strong) IBOutlet UIButton *nextKeyboardButton;
@property (nonatomic, strong) SMTEDelegateController *textExpander;
@end

@implementation KeyboardViewController

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    // Add custom view sizing constraints here
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSBundle mainBundle] loadNibNamed:@"DemoAppKeyboard" owner:self options:nil]; // Retains top level items
    
    self.keyboardView.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:self.keyboardView];  // Retains the view
    
    if (self.textExpander == nil) {
        self.textExpander = [[SMTEDelegateController alloc] init];
        self.textExpander.appGroupIdentifier = @"group.com.smileonmymac.textexpander.demoapp"; // !!! You must change this
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.textExpander willEnterForeground]; // ensure snippets are updated
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated
}

- (IBAction)nextKeyboard:(id)sender {
    [self advanceToNextInputMode];
}

- (IBAction)expandSnippet:(id)sender {
    NSUInteger cursorPosition = NSNotFound;
    NSString *stringToExpand = @"tyvm for checking out TextExpander on ddate.\n";
    NSString *expandedString = [self.textExpander stringByExpandingAbbreviations:stringToExpand cursorPosition:&cursorPosition options:0];
    if (![expandedString isEqualToString:stringToExpand]) {
        if (cursorPosition != NSNotFound) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.textDocumentProxy adjustTextPositionByCharacterOffset: cursorPosition - expandedString.length];
            });
        }
    }
    [self.textDocumentProxy insertText:expandedString];
}

- (void)textWillChange:(id<UITextInput>)textInput {
    // The app is about to change the document's contents. Perform any preparation here.
}

- (void)textDidChange:(id<UITextInput>)textInput {
    // The app has just changed the document's contents, the document context has been updated.
    
    UIColor *textColor = nil;
    if (self.textDocumentProxy.keyboardAppearance == UIKeyboardAppearanceDark) {
        textColor = [UIColor whiteColor];
    } else {
        textColor = [UIColor blackColor];
    }
    [self.nextKeyboardButton setTitleColor:textColor forState:UIControlStateNormal];
}

@end
