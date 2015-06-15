//
//  JCContactPhoneNumberViewCell.m
//  JiveOne
//
//  Created by Robert Barclay on 6/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCContactPhoneNumberTableViewCell.h"
#import "JCDrawing.h"


@implementation JCContactPhoneNumberTableViewCell

-(void)setPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    _phoneNumber = phoneNumber;
    if ([_phoneNumber isKindOfClass:[PhoneNumber class]]) {
        PhoneNumber *phoneNumber = (PhoneNumber *)_phoneNumber;
        [phoneNumber addObserver:self forKeyPath:NSStringFromSelector(@selector(type)) options:NSKeyValueObservingOptionNew context:nil];
        [phoneNumber addObserver:self forKeyPath:NSStringFromSelector(@selector(number)) options:NSKeyValueObservingOptionNew context:nil];
    }
    
    [self setNeedsLayout];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(type))] || [keyPath isEqualToString:NSStringFromSelector(@selector(number))]) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.detailEditLabel.text = _phoneNumber.type;
    self.detailTextLabel.text = _phoneNumber.type;
    self.textLabel.text = _phoneNumber.formattedNumber;
    self.textField.text = _phoneNumber.number;
}

-(void)setText:(NSString *)string
{
    if ([_phoneNumber isKindOfClass:[PhoneNumber class]]) {
        PhoneNumber *phoneNumber = (PhoneNumber *)_phoneNumber;
        phoneNumber.number = string;
    }
}

-(void)dealloc
{
    if ([_phoneNumber isKindOfClass:[PhoneNumber class]]) {
        PhoneNumber *phoneNumber = (PhoneNumber *)_phoneNumber;
        [phoneNumber removeObserver:self forKeyPath:NSStringFromSelector(@selector(type)) context:nil];
        [phoneNumber removeObserver:self forKeyPath:NSStringFromSelector(@selector(number)) context:nil];
    }
}

#pragma mark - IBActions -

-(IBAction)editDetail:(id)sender
{
    [_delegate selectTypeForContactPhoneNumberCell:self];
}

-(IBAction)dial:(id)sender
{
    [_delegate contactPhoneNumberCell:self dialPhoneNumber:_phoneNumber];
}

@end
