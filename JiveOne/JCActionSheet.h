//
//  JCActionSheet.h
//  JiveOne
//
// Action sheet Handleing with option block invocation.
//
//  Created by P Leonard on 3/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^JCActionSheetDismissBlock)(NSInteger buttonIndex);

extern NSString *const kJCActionSheetCancel;

@interface JCActionSheet : NSObject

//Class Constructor
- (id)initWithTitle:(NSString *)title dismissed:(JCActionSheetDismissBlock)dismissBlock cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;

@property(nonatomic, copy) NSString *title;


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
- (void)show:(UIView *)currentView;

// hides alert sheet or popup. use this method when you need to explicitly dismiss the alert.
// it does not need to be called if the user presses on a button
- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;

@end



