//
//  JCActionSheet.m
//  JiveOne
//
// To give you a optional block to handle using an action sheet.
//
//  Created by P Leonard on 3/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCActionSheet.h"

NSString *const kJCActionSheetCancel      = @"Cancel";

static const NSMutableArray *ActionSheets;

@interface JCActionSheet () <UIActionSheetDelegate> {
    UIActionSheet *_actionSheet;
    JCActionSheetDismissBlock _dismissBlock;
}

@end

@implementation JCActionSheet

-(id)initWithTitle:(NSString *)title
         dismissed:(JCActionSheetDismissBlock)dismissBlock
 cancelButtonTitle:(NSString *)cancelButtonTitle
 otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    // Make the array that will keep alerts alive once and for all. in practice
    // there will only ever be one item in this array and we never have to worry
    // about releasing it.
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        ActionSheets = [NSMutableArray new];
    });
    
    if ((self = [super init]))
    {
        // save the dismiss block, if any. ARC will magically do a block copy here.
        _dismissBlock = dismissBlock;
        
        // make an alert view, wiring ourselves up as the delegate
        _actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                   delegate:self
                                          cancelButtonTitle:cancelButtonTitle
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:nil];
        
        // go through the va_arg list and add any optional buttons
        va_list argumentList;
        va_start(argumentList, otherButtonTitles);
        for (NSString *string = otherButtonTitles; string; string = va_arg(argumentList, NSString *))
            [self addButtonWithTitle:string];
        va_end (argumentList);
    }
    return self;
}

-(instancetype)initWithTitle:(NSString *)title
         dismissed:(JCActionSheetDismissBlock)dismissBlock
 cancelButtonTitle:(NSString *)cancelButtonTitle
 otherButtons:(NSArray *)otherButtonTitles
{
    // Make the array that will keep alerts alive once and for all. in practice
    // there will only ever be one item in this array and we never have to worry
    // about releasing it.
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        ActionSheets = [NSMutableArray new];
    });
    
    if ((self = [super init]))
    {
        // save the dismiss block, if any. ARC will magically do a block copy here.
        _dismissBlock = dismissBlock;
        
        // make an alert view, wiring ourselves up as the delegate
        _actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                   delegate:self
                                          cancelButtonTitle:nil
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:nil];
        for (NSString *title in otherButtonTitles) {
            [_actionSheet addButtonWithTitle:title];
        }
        _actionSheet.cancelButtonIndex = [_actionSheet addButtonWithTitle:cancelButtonTitle];
    }
    return self;
}

/**
 * keep track of the alert in our private array, so it stays around, and show the alert
 */
-(void)show:(UIView*)currentView
{
    [ActionSheets addObject:self];
    
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_actionSheet showInView:currentView];
        });
    }
    else {
        [_actionSheet showInView:currentView];
    }
}

- (NSInteger)addButtonWithTitle:(NSString *)title
{
    return [_actionSheet addButtonWithTitle:title];
}

- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex
{
    return [_actionSheet buttonTitleAtIndex:buttonIndex];
}

-(void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
    [_actionSheet dismissWithClickedButtonIndex:buttonIndex animated:animated];
}

//-(UITextField *)textFieldAtIndex:(NSInteger)textFieldIndex
//{
//    return [_actionSheet textFieldAtIndex:textFieldIndex];
//}

#pragma mark - Setters -

- (void)setTitle:(NSString *)title
{
    _actionSheet.title = title;
}

- (void)setCancelButtonIndex:(NSInteger)cancelButtonIndex
{
    _actionSheet.cancelButtonIndex = cancelButtonIndex;
}

- (void)setActionsSheetStyle:(UIActionSheetStyle)actionSheetStyle
{
    _actionSheet.actionSheetStyle = actionSheetStyle;
}

#pragma mark - Getters -

-(NSString *)title
{
    return _actionSheet.title;
}

-(NSInteger)numberOfButtons
{
    return _actionSheet.numberOfButtons;
}

-(NSInteger)cancelButtonIndex
{
    return _actionSheet.cancelButtonIndex;
}

-(NSInteger)firstOtherButtonIndex
{
    return _actionSheet.firstOtherButtonIndex;
}

-(BOOL)isVisible
{
    return _actionSheet.visible;
}

-(UIActionSheetStyle)actionSheetStyle
{
    return _actionSheet.actionSheetStyle;
}

#pragma mark - Delegate Handlers -

#pragma mark UIActionSheetDelegate

/**
 * call the dismiss block if there is one
 */
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (_dismissBlock)
        _dismissBlock (actionSheet, buttonIndex);
    [ActionSheets removeObject:self];
}

@end
