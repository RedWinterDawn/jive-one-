//
//  JCContactOtherFieldTableViewCell.m
//  JiveOne
//
//  Created by Robert Barclay on 6/11/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCContactOtherFieldTableViewCell.h"

@implementation JCContactOtherFieldTableViewCell

@dynamic delegate;

-(void)setInfo:(ContactInfo *)info
{
    _info = info;
    
    [info addObserver:self forKeyPath:NSStringFromSelector(@selector(key)) options:NSKeyValueObservingOptionNew context:nil];
    [info addObserver:self forKeyPath:NSStringFromSelector(@selector(value)) options:NSKeyValueObservingOptionNew context:nil];
    [self setNeedsLayout];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(key))] || [keyPath isEqualToString:NSStringFromSelector(@selector(value))]) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_info) {
        self.detailEditLabel.text = _info.key;
        self.detailTextLabel.text = _info.key;
        self.textLabel.text = _info.value;
        self.textField.text = _info.value;
    }
}

-(void)setText:(NSString *)string
{
    _info.value = string;
}

-(void)dealloc
{
    if (_info) {
        [_info removeObserver:self forKeyPath:NSStringFromSelector(@selector(key)) context:nil];
        [_info removeObserver:self forKeyPath:NSStringFromSelector(@selector(value)) context:nil];
    }
}


@end
