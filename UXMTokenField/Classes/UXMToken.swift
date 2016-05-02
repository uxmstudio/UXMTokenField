//
//  UXMToken.swift
//  UXMTokenField
//
//  Created by Chris Anderson on 4/14/16.
//  Copyright © 2016 UXM Studio. All rights reserved.
//

import UIKit

public class UXMToken: UIView {
    
    var highlighted:Bool = false {
        didSet {

            let textColor = highlighted ? UIColor.whiteColor() : self.colorScheme
            let backgroundColor = highlighted ? self.colorScheme : UIColor.clearColor()
            
            self.titleLabel.textColor = textColor
            self.backgroundView.backgroundColor = backgroundColor
        }
    }
    var colorScheme:UIColor = UIColor.blueColor() {
        didSet {
            self.seperatorLabel.textColor = self.colorScheme
            self.titleLabel.textColor = self.colorScheme
        }
    }
    lazy var titleLabel:UILabel = {
        
        var label = UILabel(frame: CGRectMake(
            0.0,
            5.0,
            CGRectGetWidth(self.frame),
            CGRectGetHeight(self.frame)
            )
        )
        label.textColor = self.colorScheme
        label.textAlignment = .Center
        label.font = UIFont(name: "HelveticaNeue", size: 15.0)
        
        return label
    }()
    lazy var seperatorLabel:UILabel = {
        
        var label = UILabel(frame: CGRectMake(
            0.0,
            5.0,
            5.0,
            CGRectGetHeight(self.frame)
            )
        )
        label.textColor = self.colorScheme
        label.textAlignment = .Center
        label.font = UIFont(name: "HelveticaNeue", size: 15.0)
        
        return label
    }()
    lazy var backgroundView:UIView = {
        
        var backgroundView = UIView(frame: CGRectMake(
            0.0,
            0.0,
            CGRectGetWidth(self.frame),
            CGRectGetHeight(self.frame)
            )
        )
        backgroundView.layer.cornerRadius = 3.0
        
        return backgroundView
    }()
    
    
    var didTapTokenBlock:((token: UXMToken) -> (Void))?
    var tapGestureRecognizer:UITapGestureRecognizer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        
        self.addSubview(self.backgroundView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.seperatorLabel)
        
        self.tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UXMToken.didTapToken)
        )
        self.addGestureRecognizer(self.tapGestureRecognizer!)
    }
    
    func setTitleText(text: String) {
        
        self.titleLabel.text = text
        self.titleLabel.textColor = self.colorScheme
        self.titleLabel.sizeToFit()
        
        self.seperatorLabel.frame = CGRectMake(
            CGRectGetMinX(self.frame) + CGRectGetMaxX(self.titleLabel.frame),
            CGRectGetMinY(self.frame),
            CGRectGetMaxX(self.titleLabel.frame),
            28.0
        )
        
        self.frame = CGRectMake(
            CGRectGetMinX(self.frame),
            CGRectGetMinY(self.frame),
            CGRectGetMaxX(self.seperatorLabel.frame) + 2,
            CGRectGetHeight(self.frame)
        )
        
        self.backgroundView.frame = CGRectMake(
            -4.0,
            0.0,
            CGRectGetMaxX(self.titleLabel.frame) + 8,
            30.0
        )
        self.titleLabel.sizeToFit()
    }
    
    func setSeperatorText(seperator: String) {
        
        self.seperatorLabel.text = seperator
        self.seperatorLabel.textColor = self.colorScheme
        self.seperatorLabel.sizeToFit()
        self.frame = CGRectMake(
            CGRectGetMinX(self.frame),
            CGRectGetMinY(self.frame),
            CGRectGetMaxX(self.seperatorLabel.frame),
            CGRectGetHeight(self.frame)
        )
        self.seperatorLabel.sizeToFit()
    }
    
    func didTapToken() {
        self.didTapTokenBlock?(token: self)
    }
}
