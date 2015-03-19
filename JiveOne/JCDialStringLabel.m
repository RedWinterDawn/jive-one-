//
//  JCDialStringTextView.m
//  JiveOne
//
//  Created by Robert Barclay on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDialStringLabel.h"

#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber-iOS/NBAsYouTypeFormatter.h>

#import "NSString+DialString.h"


@interface JCDialStringLabel ()
{
    NSMutableString *_dialString;
}


- (void)handleTap:(UIGestureRecognizer *)recognizer;

@end

@implementation JCDialStringLabel

- (id) initWithFrame: (CGRect) frame
{
    self = [super initWithFrame:frame];
    if (self)
        [self attachTapHandler];
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self attachTapHandler];
}

- (BOOL) canPerformAction: (SEL) action withSender: (id) sender
{
    if (action == @selector(copy:))
        return YES;
    
    if (action == @selector(paste:))
        return YES;
    
    return NO;
}

-(void)setDialString:(NSString *)dialString
{
     _dialString = nil;
    if (dialString)
        _dialString = [NSMutableString stringWithString:dialString];
    
    [self updateDialString];
}

#pragma mark - Public -

-(void)append:(NSString *)string
{
    if (!_dialString)
        _dialString = [NSMutableString string];
    [_dialString appendString:string];
    [self updateDialString];
}

-(void)backspace
{
    if (!_dialString || _dialString.length == 0)
        return;
    
    _dialString = [_dialString substringToIndex:_dialString.length - 1].mutableCopy;
    [self updateDialString];
}

-(void)clear
{
    _dialString = nil;
    [self updateDialString];
    
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - Private -

- (void) attachTapHandler
{
    [self setUserInteractionEnabled:YES];
    UIGestureRecognizer *touchy = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:touchy];
}


- (void) handleTap: (UIGestureRecognizer*) recognizer
{
    [self becomeFirstResponder];
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setTargetRect:self.frame inView:self.superview];
    [menu setMenuVisible:!menu.isMenuVisible animated:YES];
}

- (void) copy: (id) sender
{
    UIPasteboard *pasteboard=[UIPasteboard generalPasteboard];
    [pasteboard setString:self.text];
}

- (void) paste: (id) sender
{
    NSData *data = [[UIPasteboard generalPasteboard] dataForPasteboardType:(NSString*)kUTTypeText];
    _dialString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding].dialString.mutableCopy;
    [self updateDialString];
}

-(NSString *)formatDialStringFromString:(NSString *)string
{
    __autoreleasing NSError *error;
    
    if (string.length < 5)
        return string;
    
    // Number with extension
    NBPhoneNumberUtil *phoneNumberUtil = [NBPhoneNumberUtil new];
    NBPhoneNumber *phoneNumber = nil;
    
        
    if (string.length > 11)
    {
        NSString *phoneNumberString = [string substringToIndex:11];
        NSString *extension = [string substringFromIndex:11];
        phoneNumber = [phoneNumberUtil parse:phoneNumberString defaultRegion:@"US" error:&error];
        if (error)
            NSLog(@"%@", [error description]);
        
        if ([string respondsToSelector:@selector(containsString:)]) {
            if ([string containsString:@"+"]) {
                return [NSString stringWithFormat:@"%@%@", [phoneNumberUtil format:phoneNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:&error], extension];
            } else {
                return [NSString stringWithFormat:@"%@%@", [phoneNumberUtil format:phoneNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&error], extension];
            }
        }  else {
            if ([string rangeOfString:@"+"].location != NSNotFound) {
                return [NSString stringWithFormat:@"%@%@", [phoneNumberUtil format:phoneNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:&error], extension];
            } else {
                return [NSString stringWithFormat:@"%@%@", [phoneNumberUtil format:phoneNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&error], extension];
            }
        }
    }
    
    NBAsYouTypeFormatter *formatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"];
    
    NSUInteger length = string.length;
    unichar buffer[length+1];
    [string getCharacters:buffer range:NSMakeRange(0, length)];
    for(int i = 0; i < length; i++)
        [formatter inputDigit:[NSString stringWithFormat:@"%C", buffer[i]]];
    return [NSString stringWithFormat:@"%@", formatter];
}


-(void)updateDialString
{
    NSString *output = [self formatDialStringFromString:_dialString];
    self.text = output;
    
    if (_delegate && [_delegate respondsToSelector:@selector(didUpdateDialString:)])
        [_delegate didUpdateDialString:_dialString];
}

@end
