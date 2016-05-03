#
# Be sure to run `pod lib lint UXMTokenField.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = "UXMTokenField"
    s.version          = "0.0.1"
    s.summary          = "An easy-to-use token field with autocompletion"
    s.description      = "Incorporate a token field for emails, user look up, etc easily without having to recreate autocompletion."

    s.homepage         = "https://github.com/uxmstudio/UXMTokenField"
    s.license          = 'MIT'
    s.author           = { "Chris Anderson" => "chris@uxmstudio.com" }
    s.source           = { :git => "https://github.com/uxmstudio/UXMTokenField.git", :tag => s.version.to_s }
    s.platform     = :ios, '8.0'
    s.requires_arc = true

    s.source_files = 'UXMTokenField/Classes/**/*'
    s.resource_bundles = {
        'UXMTokenField' => ['UXMTokenField/Assets/*.png']
    }
end