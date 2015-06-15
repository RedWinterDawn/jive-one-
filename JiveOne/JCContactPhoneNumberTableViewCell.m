//
//  JCContactPhoneNumberViewCell.m
//  JiveOne
//
//  Created by Robert Barclay on 6/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCContactPhoneNumberTableViewCell.h"

@implementation JCContactPhoneNumberTableViewCell



-(void)setPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    _phoneNumber = phoneNumber;
    self.textLabel.text         = phoneNumber.formattedNumber;
    self.detailTextLabel.text   = phoneNumber.type;
    self.textField.text         = phoneNumber.number;
    self.typeSelect.text        = phoneNumber.type;
}



-(void)setType:(NSString *)type
{
    if ([_phoneNumber isKindOfClass:[PhoneNumber class]]) {
        PhoneNumber *phoneNumber = (PhoneNumber *)_phoneNumber;
        phoneNumber.type = type;
        self.typeSelect.text = type;
        self.detailTextLabel.text = type;
    }
}

-(IBAction)textFieldValueChanged:(id)sender
{
    if ([_phoneNumber isKindOfClass:[PhoneNumber class]]) {
        PhoneNumber *phoneNumber = (PhoneNumber *)_phoneNumber;
        phoneNumber.number = self.textField.text;
        self.textLabel.text = phoneNumber.formattedNumber;
    }
}

-(IBAction)selectType:(id)sender
{
    [_delegate selectTypeForContactPhoneNumberCell:self];
}

-(IBAction)dial:(id)sender
{
    [_delegate contactPhoneNumberCell:self dialPhoneNumber:_phoneNumber];
}

@end
