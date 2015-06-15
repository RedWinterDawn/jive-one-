//
//  JCContactAddressTableViewCell.m
//  JiveOne
//
//  Created by Robert Barclay on 6/11/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCContactAddressTableViewCell.h"

@implementation JCContactAddressTableViewCell

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    BOOL editing = self.editing;
    self.cityTextField.enabled = editing;
    self.regionTextField.enabled = editing;
    self.postalCodeTextField.enabled = editing;
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    self.cityTextField.enabled = editing;
    self.regionTextField.enabled = editing;
    self.postalCodeTextField.enabled = editing;
}

-(void)setEditing:(BOOL)editing
{
    [super setEditing:editing];
    self.cityTextField.enabled = editing;
    self.regionTextField.enabled = editing;
    self.postalCodeTextField.enabled = editing;
}

-(void)setAddress:(Address *)address
{
    _address = address;
    
    [address addObserver:self forKeyPath:NSStringFromSelector(@selector(thoroughfare)) options:NSKeyValueObservingOptionNew context:nil];
    [address addObserver:self forKeyPath:NSStringFromSelector(@selector(city)) options:NSKeyValueObservingOptionNew context:nil];
    [address addObserver:self forKeyPath:NSStringFromSelector(@selector(region)) options:NSKeyValueObservingOptionNew context:nil];
    [address addObserver:self forKeyPath:NSStringFromSelector(@selector(postalCode)) options:NSKeyValueObservingOptionNew context:nil];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(thoroughfare))] ||
        [keyPath isEqualToString:NSStringFromSelector(@selector(city))] ||
        [keyPath isEqualToString:NSStringFromSelector(@selector(region))] ||
        [keyPath isEqualToString:NSStringFromSelector(@selector(postalCode))]) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.detailEditLabel.text   = _address.type;
    self.detailTextLabel.text   = _address.type;
    self.textLabel.text         = _address.thoroughfare;
    self.textField.text         = _address.thoroughfare;
    self.cityLabel.text         = _address.city;
    self.cityTextField.text     = _address.city;
    self.regionLabel.text       = _address.city;
    self.regionTextField.text   = _address.city;
    self.postalCodeLabel.text   = _address.city;
    self.postalCodeLabel.text   = _address.city;
}

-(void)dealloc
{
    if ([_address isKindOfClass:[Address class]]) {
        Address *address = (Address *)_address;
        [address removeObserver:self forKeyPath:NSStringFromSelector(@selector(thoroughfare)) context:nil];
        [address removeObserver:self forKeyPath:NSStringFromSelector(@selector(city)) context:nil];
        [address removeObserver:self forKeyPath:NSStringFromSelector(@selector(region)) context:nil];
        [address removeObserver:self forKeyPath:NSStringFromSelector(@selector(postalCode)) context:nil];
    }
}

-(IBAction)textFieldValueChanged:(id)sender
{
    if ([sender isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)sender;
        if (textField == self.textField) {
            _address.thoroughfare = textField.text;
        } else if (textField == self.cityTextField) {
            _address.city = textField.text;
        } else if (textField == self.regionTextField) {
            _address.region = textField.text;
        } else if (textField == self.postalCodeTextField) {
            _address.postalCode = textField.text;
        }
    }
}

@end
