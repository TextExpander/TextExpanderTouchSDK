//
//  tetestInputAccessortyView.h
//  teTouchSDK
//
//  Created by Brian Bucknam on 4/25/13.
//
//

#import <UIKit/UIKit.h>

@interface tetestInputAccessoryView : UIView <UIInputViewAudioFeedback> {
	UITextView *_destTextView;
}

@property (nonatomic, retain) UITextView *destTextView;

- (IBAction)insertSharp: (id)sender;	// insert # into text view
- (IBAction)insertSemi: (id)sender;		// insert ; into text view
- (IBAction)insertBoom: (id)sender;		// insert "Boom!" into text view

@end
