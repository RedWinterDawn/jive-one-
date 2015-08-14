# ignore all warnings from all pods
use_frameworks!
platform :ios, '8.0'
inhibit_all_warnings!
source 'https://github.com/CocoaPods/Specs.git'
pod 'AFNetworking', '~> 2.5.0'
pod 'AFNetworkActivityLogger', '~> 2.0.3'
pod 'uservoice-iphone-sdk', '~> 3.0'
pod 'MagicalRecord', '~> 2.2'
pod 'SocketRocket', :git => 'https://github.com/jive/SocketRocket.git', :commit => '1730fbc32ba0a0ed2c479901c36d3ffcc05f7374'
pod 'JCPhoneModule', :git => 'git@github.com:jive/iOS-JCPhoneModule.git', :commit => '2829204cf8e50daa0e23912156fac344d67e62a5'
pod 'JCMessagesViewController', :git => 'git@github.com:jive/JCMessagesViewController.git'
pod 'ELFixSecureTextFieldFont', :git => 'https://github.com/elegion/ELFixSecureTextFieldFont.git'
pod 'Appsee'
pod 'XMLDictionary', '~> 1.4'
pod 'StaticDataTableViewController'
pod 'Google/CloudMessaging'

target 'UnitTests', :exclusive => true do
    pod 'OCMock'
    pod 'OCMockito'
    pod 'Kiwi'
    pod 'OCHamcrest'
    pod 'Specta'
    pod 'Expecta'
end


target 'JCPhoneModuleTests', :exclusive => true do
    
    # TDD/BDD Testing Frame work
    pod 'Specta'
    pod 'Expecta'
    
    # Mocking
    pod 'OCMock'
    pod 'OCMockito'
    
    # UITesting
    pod 'KIF'
    
end