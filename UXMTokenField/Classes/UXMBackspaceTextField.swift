//
//  UXMBackspaceTextField.swift
//  UXMTokenField
//
//  Created by Chris Anderson on 4/14/16.
//  Copyright © 2016 UXM Studio. All rights reserved.
//

import UIKit

protocol UXMBackspaceTextFieldDelegate {
    func textFieldDidEnterBackspace(textField: UXMBackspaceTextField)
}

class UXMBackspaceTextField: UITextField {

    var backspaceDelegate:UXMBackspaceTextFieldDelegate?
    
    func keyboardInputShouldDelete(textField: UITextField) -> Bool {
        if self.text?.characters.count == 0 {
            self.backspaceDelegate?.textFieldDidEnterBackspace(self)
        }
        else {
            self.delegate?.textField!(self, shouldChangeCharactersInRange:NSMakeRange(0, 0), replacementString:"")
        }
        
        return true
    }
}
