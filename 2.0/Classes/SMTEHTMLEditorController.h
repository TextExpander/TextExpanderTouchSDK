//
//  SMTEHTMLEditorController.h
//  teiphone
//
//  Created by Brian Bucknam on 11/9/12.
//  Copyright (c) 2012-2013 SmileOnMyMac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TextExpander/SMTEDelegateController.h>

@class SMTEDelegateController;

@interface SMTEHTMLEditorController : UIViewController <SMTEFillDelegate> {
	SMTEDelegateController *_textExpander;
}

@property (nonatomic, readonly) SMTEDelegateController *textExpander;

@end
