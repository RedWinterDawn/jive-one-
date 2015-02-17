//
//  JCAlertView.h
//  JiveOne
//
//  A convenince wrapper class around a UIAlertView that uses an optional block
//  argument to handle button clicks.
//
//  The JCAlertView is an NSObject that wraps an UIAlertView instance, setting
//  itself as the delegate and encapsulating the delegate response into a
//  optional dismissed block. This simplifies implementing code that may have to
//  present multiple alert prompts by isolating thier delegate within a wrapper
//  object, and calling a dismissed block. The dismissed block is called after
//  the alert has been removed from the screen, passing the index of the button
//  clicked to the optional block.
//
//  To handle the memory retension of the UIAlertView, our instance is added to
//  a static mutable array on invocation, and is removed when the alert is
//  dismissed, releasing it and the UIAlertView from memory.
//
//  All UIAlertView methods and properties have a forwarding method on the
//  JCAlertView wrapper class. Additional class convienence methods have been
//  defined to present simple standardized OK and OK/Cancel alerts.
//
//  All button titles are Localized, calling NSLocalizedString() as they are
//  passed in to the constructor.
//
//  Created by Robert Barclay on 2/17/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^JCAlertViewDismissBlock)(NSInteger buttonIndex);

extern NSString *const kJCAlertViewOk;
extern NSString *const kJCAlertViewCancel;

@interface JCAlertView : NSObject

// Class constructor
- (id)initWithTitle:(NSString *)title message:(NSString *)message dismissed:(JCAlertViewDismissBlock)dismissBlock cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;

@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *message;

// adds a button with the title. returns the index (0 based) of where it was
// added. buttons are displayed in the order added except for the cancel button
// which will be positioned based on HI requirements. buttons cannot be customized.
- (NSInteger)addButtonWithTitle:(NSString *)title;    // returns index of button. 0 based.
- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex;
@property(nonatomic,readonly) NSInteger numberOfButtons;
@property(nonatomic) NSInteger cancelButtonIndex;      // if the delegate does not implement -alertViewCancel:, we pretend this button was clicked on. default is -1

@property(nonatomic,readonly) NSInteger firstOtherButtonIndex;	// -1 if no otherButtonTitles or initWithTitle:... not used
@property(nonatomic,readonly,getter=isVisible) BOOL visible;

// shows popup alert animated.
- (void)show;

// hides alert sheet or popup. use this method when you need to explicitly dismiss the alert.
// it does not need to be called if the user presses on a button
- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;

// Alert view style - defaults to UIAlertViewStyleDefault
@property(nonatomic,assign) UIAlertViewStyle alertViewStyle;

/* Retrieve a text field at an index - raises NSRangeException when textFieldIndex is out-of-bounds.
 The field at index 0 will be the first text field (the single field or the login field), the field at index 1 will be the password field. */
- (UITextField *)textFieldAtIndex:(NSInteger)textFieldIndex;

@end

@interface JCAlertView (Convenience)

// Display an alert view from an error
+ (JCAlertView *)alertWithError:(NSError *)error;
+ (JCAlertView *)alertWithTitle:(NSString *)title error:(NSError *)error;

// Simple OK alert
+ (JCAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message; // Defaults to show immediately
+ (JCAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message code:(NSInteger)code;
+ (JCAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message showImmediately:(BOOL)showImmediately;

// Simple Cancel, OK alert
+ (JCAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message dismissed:(JCAlertViewDismissBlock)dismissBlock; // Defaults to show immediately
+ (JCAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message dismissed:(JCAlertViewDismissBlock)dismissBlock showImmediately:(BOOL)showImmediately;

// Complex Alert
+ (JCAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message dismissed:(JCAlertViewDismissBlock)dismissBlock cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;

@end
