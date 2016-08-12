//
//  SMTextExpanderViewController.swift
//  TextExpanderDemoAppSwift
//
//  Created by Greg Scown on 7/24/16.
//  Copyright © 2016 SmileOnMyMac, LLC. All rights reserved.
//

import TextExpander

public protocol SMTextExpanderViewController {
    var textExpander : SMTEDelegateController? { get set }
}
