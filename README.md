![UXM Token Field](https://uxmstudio.com/public/images/uxmtokenfield.png)

[![Version](https://img.shields.io/cocoapods/v/UXMTokenField.svg?style=flat)](http://cocoapods.org/pods/UXMTokenField)
[![License](https://img.shields.io/cocoapods/l/UXMTokenField.svg?style=flat)](http://cocoapods.org/pods/UXMTokenField)
[![Platform](https://img.shields.io/cocoapods/p/UXMTokenField.svg?style=flat)](http://cocoapods.org/pods/UXMTokenField)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

UXMTokenField is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "UXMTokenField"
```

Usage
-----

```UXMTokenField``` provides two protocols: ```UXMTokenFieldDelegate``` and ```UXMTokenFieldDataSource```. The delegate is optional and will allow you to react to events inside of the text field. The data source on the other hand is required to provide necessary information for how the field functions.

### UXMTokenFieldDelegate
This protocol notifies you when things happen in the token field that you might want to know about.

* ```tokenField:didEnterText:``` is called when a user hits the return key on the input field.
* ```tokenField:didDeleteTokenAtIndex:``` is called when a user deletes a token at a particular index.
* ```tokenField:didChangeText:``` is called when a user changes the text in the input field.
* ```tokenField:didChangeContentHeight:``` is called when the height of the field is modified.
* ```tokenFieldDidBeginEditing:``` is called when the input field becomes first responder.

### UXMTokenFieldDataSource
This protocol allows you to provide info about what you want to present in the token field.

* ```tokenField:titleForTokenAtIndex:``` to specify what the title for the token at a particular index should be.
* ```tokenField:autocompleteValuesFor text:``` allows you to tell the token field what autocomplete values to display at any given time.
* ```numberOfTokensInTokenField:``` to specify how many tokens you have.
* ```tokenFieldCollapsedText:``` to specify what you want the token field to say in the collapsed state.


Additionally the token field has a number of other properties you can modify to customize it to your liking.

```swift

/// Public
var delegate:UXMTokenFieldDelegate
var dataSource:UXMTokenFieldDataSource

var maxHeight:CGFloat
var verticalInset:CGFloat
var horizontalInset:CGFloat
var tokenPadding:CGFloat
var minInputWidth:CGFloat

var inputTextFieldKeyboardType:UIKeyboardType
var inputTextFieldKeyboardAppearance:UIKeyboardAppearance

var autocorrectionType:UITextAutocorrectionType
var autocapitalizationType:UITextAutocapitalizationType
var inputTextFieldAccessoryView:UIView

var delimiters:[String]
var tokens:[UXMToken]
var tokenSeperator:String
var placeholderText:String
var placeholderAttributedText:NSAttributedString
var colorScheme:UIColor
var hideKeyboardOnAutocomplete:Bool

```

##Tips
* If the autocomplete table is not appearing, this could be because the parent elements clip to bound settings are preventing it from being seen.
* Autocomplete cells allow for either an array of strings, or an array of ```UXMAutocompleteItem```'s to be passed in. While a string will display as just one line of text, an autocomplete item allows for a subtitle as well.

# Author
Chris Anderson:
- chris@uxmstudio.com
- [Home Page](http://uxmstudio.com)

# License

UXMTokenField is available under the MIT license. See the LICENSE file for more info.
