//
//  ViewController.swift
//  UXMTokenField
//
//  Created by Chris Anderson on 04/27/2016.
//  Copyright (c) 2016 Chris Anderson. All rights reserved.
//

import UIKit
import UXMTokenField

class ViewController: UIViewController {

    @IBOutlet var tokenField:UXMTokenField!
    var names:[String] = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tokenField.delegate = self
        self.tokenField.dataSource = self
        self.tokenField.placeholderText = "Tap to start typing"
        self.tokenField.delimiters = [",", ";", "--"]
        self.tokenField.tokenSeperator = "→"
        self.tokenField.colorScheme = UIColor.blueColor()
        self.tokenField.horizontalInset = 13.0
        
        let toolbar = UIToolbar(frame: CGRectMake(0, 0, self.view.frame.size.width, 50))
        toolbar.barStyle = UIBarStyle.Default
        toolbar.items = [
            UIBarButtonItem(title: "Clear", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ViewController.clearRoute)),
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ViewController.closeKeyboard))]
        toolbar.sizeToFit()
        self.tokenField.inputTextFieldAccessoryView = toolbar
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func clearRoute() {
        self.names.removeAll()
        self.tokenField.reloadData()
    }
    
    func closeKeyboard() {
        self.tokenField.resignFirstResponder()
    }
}

extension ViewController: UXMTokenFieldDelegate {
    
    func tokenField(tokenField: UXMTokenField, didEnterText text: String) {
        
        self.names.append(text)
        self.tokenField.reloadData()
    }
    
    func tokenField(tokenField: UXMTokenField, didDeleteTokenAtIndex index: Int) {
        
        self.names.removeAtIndex(index)
        self.tokenField.reloadData()
    }
}

extension ViewController: UXMTokenFieldDataSource {
    func tokenField(tokenField: UXMTokenField, titleForTokenAtIndex index: Int) -> String {
        return self.names[index]
    }
    
    func numberOfTokensInTokenField(tokenField: UXMTokenField) -> Int {
        return self.names.count
    }
    
    func tokenField(tokenField:UXMTokenField, autocompleteValuesFor text:String) -> [AnyObject] {
        
        return [ "John", "James", "Peter", "Paul", "Susan", "Jane", "Claire" ]
    }
}