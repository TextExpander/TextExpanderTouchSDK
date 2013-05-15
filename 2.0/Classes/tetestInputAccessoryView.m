//
//  tetestInputAccessoryView.m
//  teTouchSDK
//
//  Created by Brian Bucknam on 4/25/13.
//
//

#import "tetestInputAccessoryView.h"

@implementation tetestInputAccessoryView

@synthesize destTextView = _destTextView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		self.backgroundColor = [UIColor blueColor];
		UIButton *sharpButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		sharpButton.frame = CGRectMake(20.0, 3.0, 40.0, 26.0);
		[sharpButton setTitle: @"#" forState:UIControlStateNormal];
		[sharpButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[sharpButton addTarget:self action:@selector(insertSharp:)
			  forControlEvents:UIControlEventTouchUpInside];
		[self addSubview: sharpButton];
		UIButton *semiButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		semiButton.frame = CGRectMake(70.0, 3.0, 40.0, 26.0);
		[semiButton setTitle: @";" forState:UIControlStateNormal];
		[semiButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[semiButton addTarget:self action:@selector(insertSemi:)
			 forControlEvents:UIControlEventTouchUpInside];
		[self addSubview: semiButton];
		UIButton *boomButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		boomButton.frame = CGRectMake(140.0, 3.0, 80.0, 26.0);
		[boomButton setTitle: @"Boom!" forState:UIControlStateNormal];
		[boomButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[boomButton addTarget:self action:@selector(insertBoom:)
			 forControlEvents:UIControlEventTouchUpInside];
		[self addSubview: boomButton];
    }
    return self;
}

// Insert text into a UITextView in such a way that the delegate gets notified as if the user typed or pasted the text
- (BOOL)insertArbitraryText: (NSString*)insertStr intoTextView: (UITextView*)tv {
	BOOL insertIt = YES;
	if (tv.delegate != nil && [tv.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)])
		insertIt = [tv.delegate textView: tv shouldChangeTextInRange: tv.selectedRange replacementText: insertStr];
	if (insertIt) {
		[tv replaceRange: tv.selectedTextRange withText: insertStr];
		[[UIDevice currentDevice] playInputClick];
	}
	return insertIt;
}

- (IBAction)insertSharp: (id)sender {
	// insert # into text view
	[self insertArbitraryText: @"#" intoTextView: self.destTextView];
}

- (IBAction)insertSemi: (id)sender {
	// insert ; into text view
	[self insertArbitraryText: @";" intoTextView: self.destTextView];
}

- (IBAction)insertBoom: (id)sender {
	// insert "Boom!" into text view
	[self insertArbitraryText: @"Boom!" intoTextView: self.destTextView];
}

- (BOOL)enableInputClicksWhenVisible {
	return YES;
}

@end
