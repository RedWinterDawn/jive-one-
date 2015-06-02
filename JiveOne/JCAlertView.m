
//
//  JCAlertView.m
//  JiveOne
//
//  Created by Robert Barclay on 2/17/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAlertView.h"

NSString *const kJCAlertViewOk          = @"OK";
NSString *const kJCAlertViewCancel      = @"Cancel";

static const NSMutableArray *alerts;

@interface JCAlertView () <UIAlertViewDelegate> {
    UIAlertView *_alertView;
    JCAlertViewDismissBlock _dismissBlock;
}

@end

@implementation JCAlertView

-(id)initWithTitle:(NSString *)title
           message:(NSString *)message
         dismissed:(JCAlertViewDismissBlock)dismissBlock
 cancelButtonTitle:(NSString *)cancelButtonTitle
 otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    // Make the array that will keep alerts alive once and for all. in practice
    // there will only ever be one item in this array and we never have to worry
    // about releasing it.
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        alerts = [NSMutableArray new];
    });
    
    if ((self = [super init]))
    {
        // save the dismiss block, if any. ARC will magically do a block copy here.
        _dismissBlock = dismissBlock;
        
        // make an alert view, wiring ourselves up as the delegate
        _alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(title,nil)
                                                message:NSLocalizedString(message,nil)
                                               delegate:self
                                      cancelButtonTitle:NSLocalizedString(cancelButtonTitle,nil)
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

/**
 * keep track of the alert in our private array, so it stays around, and show the alert
 */
-(void)show
{
    [alerts addObject:self];
    
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_alertView show];
        });
    }
    else {
        [_alertView show];
    }
}

- (NSInteger)addButtonWithTitle:(NSString *)title
{
    return [_alertView addButtonWithTitle:NSLocalizedString(title, nil)];
}

- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex
{
    return [_alertView buttonTitleAtIndex:buttonIndex];
}

-(void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
    [_alertView dismissWithClickedButtonIndex:buttonIndex animated:animated];
}

-(UITextField *)textFieldAtIndex:(NSInteger)textFieldIndex
{
    return [_alertView textFieldAtIndex:textFieldIndex];
}

#pragma mark - Setters -

- (void)setTitle:(NSString *)title
{
    _alertView.title = NSLocalizedString(title,nil);
}

- (void)setMessage:(NSString *)message
{
    _alertView.message = NSLocalizedString(message,nil);
}

- (void)setCancelButtonIndex:(NSInteger)cancelButtonIndex
{
    _alertView.cancelButtonIndex = cancelButtonIndex;
}

- (void)setAlertViewStyle:(UIAlertViewStyle)alertViewStyle
{
    _alertView.alertViewStyle = alertViewStyle;
}

#pragma mark - Getters -

-(NSString *)title
{
    return _alertView.title;
}

-(NSString *)message
{
    return _alertView.message;
}

-(NSInteger)numberOfButtons
{
    return _alertView.numberOfButtons;
}

-(NSInteger)cancelButtonIndex
{
    return _alertView.cancelButtonIndex;
}

-(NSInteger)firstOtherButtonIndex
{
    return _alertView.firstOtherButtonIndex;
}

-(BOOL)isVisible
{
    return _alertView.visible;
}

-(UIAlertViewStyle)alertViewStyle
{
    return _alertView.alertViewStyle;
}

#pragma mark - Delegate Handlers -

#pragma mark UIAlertViewDelegate

/**
 * call the dismiss block if there is one
 */
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (_dismissBlock)
        _dismissBlock (buttonIndex);
    [alerts removeObject:self];
}

@end


@implementation JCAlertView (Convenience)

+ (JCAlertView *)alertWithError:(NSError *)error
{
    return [JCAlertView alertWithTitle:@"Warning" error:error];
}

+ (JCAlertView *)alertWithError:(NSError *)error dismissed:(JCAlertViewDismissBlock)dismissBlock cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    NSString *message = [error localizedDescription];
    if (!message) {
        message = [error localizedFailureReason];
    }
    
    NSError *underlyingError = [self underlyingErrorForError:error];
    NSString *underlyingFailureReason = [underlyingError localizedFailureReason];
    if(underlyingFailureReason) {
        message = [NSString stringWithFormat:@"%@\n(%li: %@)", NSLocalizedString(message, nil), (long)underlyingError.code, underlyingFailureReason];
    }
    else {
        message = [NSString stringWithFormat:@"%@\n(%li)", NSLocalizedString(message, nil), (long)underlyingError.code];
    }
    JCAlertView *alertView = [[JCAlertView alloc] initWithTitle:@"Warning" message:message dismissed:dismissBlock cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
    if (alertView)
    {
        va_list argumentList;
        va_start(argumentList, otherButtonTitles);
        for (NSString *title = otherButtonTitles; title != nil; title = va_arg(argumentList, NSString*))
            [alertView addButtonWithTitle:title];
        va_end(argumentList);
    }
    [alertView show];
    return alertView;
}

+(JCAlertView *)alertWithTitle:(NSString *)title error:(NSError *)error
{
    NSString *message = [error localizedDescription];
    if (!message) {
        message = [error localizedFailureReason];
    }
    NSError *underlyingError = [self underlyingErrorForError:error];
    NSString *underlyingFailureReason = [underlyingError localizedFailureReason];
    if(underlyingFailureReason) {
        message = [NSString stringWithFormat:@"%@\n(%li: %@)", NSLocalizedString(message, nil), (long)underlyingError.code, underlyingFailureReason];
    }
    else {
        message = [NSString stringWithFormat:@"%@\n(%li)", NSLocalizedString(message, nil), (long)underlyingError.code];
    }
    return [JCAlertView alertWithTitle:title message:message showImmediately:YES];
}

+(JCAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message code:(NSInteger)code
{
    message = [NSString stringWithFormat:@"%@\n(%li)", NSLocalizedString(message, nil), (long)code];
    return [JCAlertView alertWithTitle:title message:message showImmediately:YES];
}

+(JCAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message
{
    return [JCAlertView alertWithTitle:title message:message showImmediately:YES];
}

+(JCAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message showImmediately:(BOOL)showImmediately
{
    JCAlertView *alertView = [JCAlertView alertWithTitle:title message:message dismissed:NULL cancelButtonTitle:kJCAlertViewOk otherButtonTitles:nil];
    if (showImmediately)
        [alertView show];
    return alertView;
}

+(JCAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message dismissed:(JCAlertViewDismissBlock)dismissBlock
{
    JCAlertView *alertView = [JCAlertView alertWithTitle:title message:message dismissed:dismissBlock showImmediately:YES];
    return alertView;
}

+(JCAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message dismissed:(JCAlertViewDismissBlock)dismissBlock showImmediately:(BOOL)showImmediately
{
    JCAlertView *alertView = [JCAlertView alertWithTitle:title message:message dismissed:dismissBlock cancelButtonTitle:kJCAlertViewCancel otherButtonTitles:kJCAlertViewOk,nil];
    
    if (showImmediately)
        [alertView show];
    return alertView;
}

+(JCAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message dismissed:(JCAlertViewDismissBlock)dismissBlock cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    JCAlertView *alertView = [[JCAlertView alloc] initWithTitle:title message:message dismissed:dismissBlock cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
    if (alertView)
    {
        va_list argumentList;
        va_start(argumentList, otherButtonTitles);
        for (NSString *title = otherButtonTitles; title != nil; title = va_arg(argumentList, NSString*))
            [alertView addButtonWithTitle:title];
        va_end(argumentList);
    }
    return alertView;
}

+(NSError *)underlyingErrorForError:(NSError *)error
{
    NSError *underlyingError = [error.userInfo objectForKey:NSUnderlyingErrorKey];
    if (underlyingError) {
        return [self underlyingErrorForError:underlyingError];
    }
    return error;
}

+(NSInteger)underlyingErrorCodeForError:(NSError *)error
{
    error = [self underlyingErrorForError:error];
    if ([error.domain isEqualToString:AFURLResponseSerializationErrorDomain]) {
        NSHTTPURLResponse *urlResponse = [error.userInfo valueForKey:AFNetworkingOperationFailingURLResponseErrorKey];
        return urlResponse.statusCode;
    }
    return error.code;
}

@end
