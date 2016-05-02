//
//  UXMTokenField.swift
//  UXMTokenField
//
//  Created by Chris Anderson on 4/14/16.
//  Copyright © 2016 UXM Studio. All rights reserved.
//

import UIKit

@objc public protocol UXMTokenFieldDelegate {
    optional func tokenField(tokenField:UXMTokenField, didEnterText text:String)
    optional func tokenField(tokenField:UXMTokenField, didDeleteTokenAtIndex index:Int)
    optional func tokenField(tokenField:UXMTokenField, didChangeText text:String)
    optional func tokenField(tokenField:UXMTokenField, didChangeContentHeight height:CGFloat)
    optional func tokenFieldDidBeginEditing(tokenField:UXMTokenField)
    optional func tokenFieldDidEndEditing(tokenField:UXMTokenField)
}

@objc public protocol UXMTokenFieldDataSource {
    func tokenField(tokenField:UXMTokenField, titleForTokenAtIndex index:Int) -> String
    func numberOfTokensInTokenField(tokenField:UXMTokenField) -> Int
    func tokenField(tokenField:UXMTokenField, autocompleteValuesFor text:String) -> [AnyObject]
    optional func tokenField(tokenField:UXMTokenField, colorSchemeForTokenAtIndex index:Int) -> UIColor
    optional func tokenFieldCollapsedText(tokenField:UXMTokenField) -> String
}

public class UXMTokenField: UIView {
    
    public var delegate:UXMTokenFieldDelegate?
    public var dataSource:UXMTokenFieldDataSource?
    
    public var maxHeight:CGFloat = 150.0
    public var verticalInset:CGFloat = 7.0
    public var horizontalInset:CGFloat = 15.0
    public var tokenPadding:CGFloat = 0.0
    public var minInputWidth:CGFloat = 50.0
    
    public var inputTextFieldKeyboardType:UIKeyboardType = .Default
    public var inputTextFieldKeyboardAppearance:UIKeyboardAppearance = .Default
    
    public var autocorrectionType:UITextAutocorrectionType = .No {
        didSet {
            self.inputTextField.autocorrectionType = self.autocorrectionType
            self.invisibleTextField.autocorrectionType = self.autocorrectionType
        }
    }
    public var autocapitalizationType:UITextAutocapitalizationType = .Sentences {
        didSet {
            self.inputTextField.autocapitalizationType = self.autocapitalizationType
            self.invisibleTextField.autocapitalizationType = self.autocapitalizationType
        }
    }
    public var inputTextFieldAccessoryView:UIView? {
        didSet {
            self.inputTextField.inputAccessoryView = self.inputTextFieldAccessoryView
        }
    }
    
    public var delimiters:[String] = [","]
    public var tokens:[UXMToken] = []
    public var tokenSeperator:String = ","
    public var placeholderText:String = ""
    public var placeholderAttributedText:NSAttributedString?
    var autocompletion:[AnyObject] = []
    lazy var originalHeight:CGFloat = self.frame.size.height
    var tapGestureRecognizer:UITapGestureRecognizer?
    public var colorScheme:UIColor = UIColor.blueColor()
    var collapsedLabel:UILabel?
    public var hideKeyboardOnAutocomplete:Bool = false
    var lastKeyboardFrame:CGRect = CGRectMake(0, 0, 0, 0)
    
    internal var isSelectingAutocomplete:Bool = false
    
    lazy var scrollView:UIScrollView = {
        let scrollView = UIScrollView(frame: CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)))
        scrollView.scrollsToTop = false
        scrollView.contentSize = CGSizeMake(
            CGRectGetWidth(self.frame) - self.horizontalInset * 2,
            CGRectGetHeight(self.frame) - self.verticalInset * 2)
        scrollView.alwaysBounceHorizontal = false
        scrollView.contentInset = UIEdgeInsetsMake(self.verticalInset,
                                                   self.horizontalInset,
                                                   self.verticalInset,
                                                   self.horizontalInset)
        scrollView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        return scrollView
    }()
    
    lazy var inputTextField:UXMBackspaceTextField = {
        
        let textField = UXMBackspaceTextField()
        textField.keyboardType = self.inputTextFieldKeyboardType
        textField.font = UIFont(name: "HelveticaNeue", size: 15.0)
        textField.autocorrectionType = self.autocorrectionType
        textField.autocapitalizationType = self.autocapitalizationType
        textField.tintColor = self.colorScheme
        textField.delegate = self
        textField.backspaceDelegate = self
        textField.inputAccessoryView = self.inputTextFieldAccessoryView
        
        return textField
    }()
    
    lazy var invisibleTextField:UXMBackspaceTextField = {
        
        let textField = UXMBackspaceTextField(frame: CGRectZero)
        textField.autocorrectionType = self.autocorrectionType
        textField.autocapitalizationType = self.autocapitalizationType
        textField.backspaceDelegate = self
        self.addSubview(textField)
        
        return textField
    }()
    
    var autocompleteTableView:UITableViewController?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override public func awakeFromNib() {
        self.setup()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override public func isFirstResponder() -> Bool {
        return self.inputTextField.isFirstResponder()
    }
    
    override public func becomeFirstResponder() -> Bool {
        self.layoutTokensAndInput(true)
        self.inputTextFieldBecomeFirstResponder()
        return true
    }
    
    override public func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return self.inputTextField.resignFirstResponder()
    }
    
    
    
    //MARK: Setup
    func setup() {
        
        self.originalHeight = CGRectGetHeight(self.frame)
        self.layoutScrollView()
        self.reloadData()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(UXMTokenField.keyboardWillShowNotification(_:)),
            name: UIKeyboardWillShowNotification,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(UXMTokenField.keyboardWillHideNotification(_:)),
            name: UIKeyboardWillHideNotification,
            object: nil
        )
    }
    
    public func collapse() {
        
        self.layoutCollapsedLabel()
    }
    
    public func reloadData() {
        self.layoutTokensAndInput(true)
        self.hideSuggestions()
    }
    
    
    
    
    //MARK: - View Layout
    override public func layoutSubviews() {
        
        super.layoutSubviews()
        
        self.scrollView.contentSize  = CGSizeMake(
            CGRectGetWidth(self.frame) - self.horizontalInset * 2,
            CGRectGetHeight(self.frame) - self.verticalInset * 2
        )
        
        if self.isCollapsed() {
            self.layoutCollapsedLabel()
        }
        else {
            self.layoutTokensAndInput(false)
        }
        
        if let text = self.inputTextField.text where !text.isEmpty {
            
            self.provideSuggestions()
        }
        else {
            if autocompleteTableView?.tableView.superview != nil {
                autocompleteTableView?.tableView.removeFromSuperview()
            }
        }
    }
    
    func layoutCollapsedLabel() {
        
        self.collapsedLabel?.removeFromSuperview()
        self.scrollView.hidden = true
        
        var frame = self.frame
        frame.size.height = self.originalHeight
        self.frame = frame
        
        var currentX:CGFloat = 0.0
        
        
        self.layoutCollapsedLabel(&currentX)
        
        self.tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UXMTokenField.handleSingleTap)
        )
        self.addGestureRecognizer(self.tapGestureRecognizer!)
    }
    
    func layoutTokensAndInput(adjustFrame: Bool) {
        
        self.collapsedLabel?.removeFromSuperview()
        let inputFieldShouldBecomeFirstResponder = self.inputTextField.isFirstResponder()
        
        for subview in self.scrollView.subviews {
            subview.removeFromSuperview()
        }
        
        self.scrollView.hidden = false
        if let recognizer = self.tapGestureRecognizer {
            self.removeGestureRecognizer(recognizer)
        }
        
        self.tokens = []
        
        var currentX:CGFloat = 0.0
        var currentY:CGFloat = 0.0
        
        self.layoutTokens(&currentX, currentY: &currentY)
        self.layoutInputTextField(&currentX, currentY: &currentY, clearInput:adjustFrame)
        
        if adjustFrame {
            self.adjustHeight(currentY)
        }
        
        self.updateInputTextField()
        
        if inputFieldShouldBecomeFirstResponder {
            self.inputTextFieldBecomeFirstResponder()
        }
        else {
            self.focusInputTextField()
        }
    }
    
    func isCollapsed() -> Bool {
        return self.collapsedLabel?.superview != nil
    }
    
    func layoutScrollView() {
        self.addSubview(self.scrollView)
    }
    
    func layoutInputTextField(inout currentX: CGFloat, inout currentY: CGFloat, clearInput: Bool) {
        
        var inputTextFieldWidth = self.scrollView.contentSize.width - currentX
        
        if inputTextFieldWidth < self.minInputWidth {
            inputTextFieldWidth = self.scrollView.contentSize.width
            currentY += self.heightForToken()
            currentX = 0
        }
        
        let inputTextField = self.inputTextField
        if clearInput {
            inputTextField.text = ""
        }
        inputTextField.frame = CGRectMake(
            currentX,
            currentY + 1,
            inputTextFieldWidth,
            self.heightForToken() - 1
        )
        inputTextField.tintColor = self.colorScheme
        self.scrollView.addSubview(inputTextField)
    }
    
    func layoutCollapsedLabel(inout currentX: CGFloat) {
        
        let label:UILabel = UILabel(frame: CGRectMake(
            currentX,
            0.0,
            self.frame.width - currentX - self.horizontalInset,
            30.0
            )
        )
        label.font = UIFont(name: "HelveticaNeue", size: 15.0)
        label.text = self.collapsedText()
        label.textColor = self.colorScheme
        label.minimumScaleFactor = 5.0 / label.font.pointSize
        label.adjustsFontSizeToFitWidth = true
        self.addSubview(label)
        self.collapsedLabel = label
    }
    
    func layoutTokens(inout currentX: CGFloat, inout currentY: CGFloat) {
        
        for i in 0 ..< self.numberOfTokens() {
            
            let title = self.titleForTokenAtIndex(i)
            let token = UXMToken()
            
            token.didTapTokenBlock = {
                [weak self] selToken in
                
                if let strongSelf = self {
                    strongSelf.didTapToken(selToken)
                }
            }
            
            token.setSeperatorText(self.tokenSeperator)
            token.setTitleText("\(title)")
            token.colorScheme = self.colorSchemeForTokenAtIndex(i)
            
            self.tokens.append(token)
            
            if currentX + token.frame.width <= self.scrollView.contentSize.width {
                token.frame = CGRectMake(
                    currentX,
                    currentY,
                    token.frame.width,
                    self.heightForToken()
                )
            }
            else {
                currentY += self.heightForToken()
                currentX = 0
                
                var tokenWidth = token.frame.width
                if tokenWidth > self.scrollView.contentSize.width {
                    tokenWidth = self.scrollView.contentSize.width
                }
                
                token.frame = CGRectMake(
                    currentX,
                    currentY,
                    tokenWidth,
                    self.heightForToken()
                )
            }
            currentX += token.frame.width + self.tokenPadding
            self.scrollView.addSubview(token)
        }
    }
    
    
    
    
    //MARK: - Keyboard Layout
    func keyboardWillShowNotification(notification: NSNotification) {
        updateBottomLayoutConstraintWithNotification(notification)
    }
    
    func keyboardWillHideNotification(notification: NSNotification) {
        updateBottomLayoutConstraintWithNotification(notification)
    }
    
    func updateBottomLayoutConstraintWithNotification(notification: NSNotification) {
        let userInfo = notification.userInfo!
        
        let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let convertedKeyboardEndFrame = self.convertRect(keyboardEndFrame, fromView: self.window)
        
        self.lastKeyboardFrame = convertedKeyboardEndFrame
    }
    
    func rectSubtract(rect1: CGRect, rect2: CGRect, edge: CGRectEdge) -> CGRect {
        
        let intersection:CGRect = CGRectIntersection(rect1, rect2)
        
        if CGRectIsNull(intersection) {
            return rect1
        }
        
        let chopAmount:CGFloat = (edge == CGRectEdge.MaxXEdge || edge == CGRectEdge.MinXEdge)
            ? intersection.size.width
            : intersection.size.height
        
        let rect3 = UnsafeMutablePointer<CGRect>.alloc(1)
        let throwaway = UnsafeMutablePointer<CGRect>.alloc(1)
        
        CGRectDivide(rect1, throwaway, rect3, chopAmount, edge)
        return rect3.memory
    }
    
    
    
    
    //MARK: - Private
    func heightForToken() -> CGFloat {
        return 30.0
    }
    
    func inputTextFieldBecomeFirstResponder() {
        
        if self.inputTextField.isFirstResponder() {
            return
        }
        
        self.inputTextField.becomeFirstResponder()
        self.delegate?.tokenFieldDidBeginEditing?(self)
    }
    
    func adjustHeight(currentY: CGFloat) {
        
        let oldHeight = self.frame.height
        var height:CGFloat = 0.0
        
        if currentY + self.heightForToken() > CGRectGetHeight(self.frame) {
            
            if currentY + self.heightForToken() <= self.maxHeight {
                height = currentY + self.heightForToken() + self.verticalInset * 2
            }
            else {
                height = self.maxHeight
            }
        }
        else {
            
            if currentY + self.heightForToken() > self.originalHeight {
                height = currentY + self.heightForToken() + self.verticalInset * 2
            }
            else {
                height = self.originalHeight
            }
        }
        
        if oldHeight != height {
            var frame = self.frame
            frame.size.height = height
            self.frame = frame
            
            self.delegate?.tokenField?(self, didChangeContentHeight: height)
        }
    }
    
    func handleSingleTap() {
        self.becomeFirstResponder()
    }
    
    func didTapToken(token: UXMToken) {
        
        for aToken in self.tokens {
            if aToken == token {
                aToken.highlighted = !aToken.highlighted
            }
            else {
                aToken.highlighted = false
            }
        }
        self.setCursorVisibility()
    }
    
    func unhighlightAllTokens() {
        
        for token in self.tokens {
            token.highlighted = false
        }
        self.setCursorVisibility()
    }
    
    func setCursorVisibility() {
        
        let highlightedTokens = self.tokens.filter({$0.highlighted})
        
        let visible = highlightedTokens.count == 0
        if visible {
            self.inputTextFieldBecomeFirstResponder()
        }
        else {
            self.invisibleTextField.becomeFirstResponder()
        }
    }
    
    func updateInputTextField() {
        
        if self.tokens.count > 0 {
            self.inputTextField.placeholder = nil
            return
        }
        
        if let attributedText = self.placeholderAttributedText {
            self.inputTextField.attributedPlaceholder = attributedText
        }
        else {
            self.inputTextField.placeholder = self.placeholderText
        }
    }
    
    func focusInputTextField() {
        let contentOffset = self.scrollView.contentOffset
        let targetY = self.inputTextField.frame.origin.y + self.heightForToken() - self.maxHeight
        if targetY > contentOffset.y {
            self.scrollView.setContentOffset(CGPointMake(contentOffset.x, targetY), animated: false)
        }
    }
    
    
    
    
    //MARK: - Autocomplete Table
    func provideSuggestions() {
        
        if let tableViewController = autocompleteTableView {
            
            tableViewController.tableView.reloadData()
        }
        else {
            let tableViewController = UITableViewController()
            let tableView = tableViewController.tableView
            tableView.delegate = self
            tableView.dataSource = self
            
            let autocompleteTableTapped = UITapGestureRecognizer(
                target: self,
                action: #selector(UXMTokenField.autocompleteTableTapped(_:))
            )
            autocompleteTableTapped.cancelsTouchesInView = true
            tableView.addGestureRecognizer(autocompleteTableTapped)
            
            var popoverFrame:CGRect = self.frame
            popoverFrame.origin.y += self.frame.size.height
            popoverFrame.size.height = 320
            popoverFrame = rectSubtract(popoverFrame, rect2: self.lastKeyboardFrame, edge: CGRectEdge.MaxYEdge)
            popoverFrame.size.height += self.heightForToken()
            
            tableView.frame = popoverFrame
            
            self.superview?.addSubview(tableView)
            tableView.alpha = 1.0
            
            self.autocompleteTableView = tableViewController
        }
    }
    
    func hideSuggestions() {
        if let tableViewController = autocompleteTableView {
            tableViewController.tableView.removeFromSuperview()
            self.autocompleteTableView = nil
        }
    }
    
    func autocompleteTableTapped(tap: UITapGestureRecognizer) {
        
        if let tableViewController = autocompleteTableView {
            
            let location = tap.locationInView(tableViewController.tableView)
            let path = tableViewController.tableView.indexPathForRowAtPoint(location)
            if let path = path {
                self.isSelectingAutocomplete = true
                self.tableView(tableViewController.tableView, didSelectRowAtIndexPath: path)
            }
        }
    }
    
    
    
    
    //MARK: - Data Source
    func titleForTokenAtIndex(index: Int) -> String {
        
        if let text = self.dataSource?.tokenField(self, titleForTokenAtIndex: index) {
            return text
        }
        return ""
    }
    
    func numberOfTokens() -> Int {
        if let numberOfTokens = self.dataSource?.numberOfTokensInTokenField(self) {
            return numberOfTokens
        }
        return 0
    }
    
    func collapsedText() -> String {
        
        if let text = self.dataSource?.tokenFieldCollapsedText?(self) {
            return text
        }
        return ""
    }
    
    func colorSchemeForTokenAtIndex(index: Int) -> UIColor {
        
        if let color = self.dataSource?.tokenField?(self, colorSchemeForTokenAtIndex: index) {
            return color
        }
        return self.colorScheme
    }
}




//MARK: - UITableViewDelegate
extension UXMTokenField: UITableViewDelegate {
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let item = self.autocompletion[indexPath.row]
        
        if let autocompleteItem = item as? UXMAutocompleteItem {
            self.delegate?.tokenField?(self, didEnterText: autocompleteItem.title)
        }
        else {
            self.delegate?.tokenField?(self, didEnterText: (item as! String))
        }
        self.isSelectingAutocomplete = false
    }
}




//MARK: - UITableViewDataSource
extension UXMTokenField: UITableViewDataSource {
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.autocompletion.count
    }
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let item = self.autocompletion[indexPath.row]
        
        if let autocompleteItem = item as? UXMAutocompleteItem {
            let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "autocompleteItemCell")
            cell.textLabel?.text = autocompleteItem.title
            cell.detailTextLabel?.text = autocompleteItem.subtitle
            return cell
        }
        else {
            
            let cell = UITableViewCell(style: .Default, reuseIdentifier: "autocompleteSingleCell")
            cell.textLabel?.text = item as? String
            return cell
        }
    }
}




//MARK: - FABackspaceTextFieldDelegate
extension UXMTokenField: UXMBackspaceTextFieldDelegate {
    
    func textFieldDidEnterBackspace(textField: UXMBackspaceTextField) {
        
        if self.numberOfTokens() > 0 {
            var didDeleteToken = false
            for token in self.tokens {
                if token.highlighted {
                    self.delegate?.tokenField?(self, didDeleteTokenAtIndex: self.tokens.indexOf(token)!)
                    didDeleteToken = true
                    break
                }
            }
            if !didDeleteToken {
                let lastToken = self.tokens.last
                lastToken?.highlighted = true
            }
            self.setCursorVisibility()
        }
    }
}




//MARK: - UITextFieldDelegate
extension UXMTokenField: UITextFieldDelegate {
    
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if let text = textField.text where !text.isEmpty {
            self.delegate?.tokenField?(self, didEnterText: text)
        }
        
        return false
    }
    
    public func textFieldDidBeginEditing(textField: UITextField) {
        
        self.delegate?.tokenFieldDidBeginEditing?(self)
        
        if textField == self.inputTextField {
            self.unhighlightAllTokens()
        }
    }
    
    public func textFieldDidEndEditing(textField: UITextField) {
        
        self.delegate?.tokenFieldDidEndEditing?(self)
    }
    
    public func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        if self.hideKeyboardOnAutocomplete {
            return true
        }
        if self.isSelectingAutocomplete {
            return false
        }
        return true
    }
    
    public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        self.unhighlightAllTokens()
        
        let newString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        let nStrLen:Int = newString.characters.count
        
        if let dataSource = dataSource {
            autocompletion = dataSource.tokenField(self, autocompleteValuesFor: newString)
        }
        
        if nStrLen <= 0 {
            self.hideSuggestions()
        }
        else {
            self.provideSuggestions()
        }
        
        for delimiter in delimiters {
            
            let delLen:Int = delimiter.characters.count
            
            if nStrLen > delLen
                && (newString as NSString).substringFromIndex(nStrLen - delLen) == delimiter {
                
                let enteredString = (newString as NSString).substringToIndex(nStrLen - delLen)
                if !enteredString.isEmpty {
                    self.delegate?.tokenField?(self, didEnterText: enteredString)
                    return false
                }
            }
        }
        return true
    }
}