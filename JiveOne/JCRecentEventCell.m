//
//  JCRecentEventCell.m
//  JiveOne
//
//  Created by Robert Barclay on 10/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRecentEventCell.h"
#import "Contact.h"
#import "PBX.h"

@interface JCRecentEventCell(){
    UIFont *_dateFont;
    UIFont *_boldDateFont;
    
    UIFont *_nameFont;
    UIFont *_boldNameFont;
    
    UIFont *_extensionFont;
    UIFont *_boldExtensionFont;
    
    UIFont *_numberFont;
    UIFont *_boldNumberFont;
}

@end

@implementation JCRecentEventCell

-(void)awakeFromNib
{
    _dateFont = self.date.font;
    _boldDateFont = [UIFont fontWithDescriptor:[[_dateFont fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:_dateFont.pointSize];
    
    _nameFont = self.name.font;
    _boldNameFont = [UIFont fontWithDescriptor:[[_nameFont fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:_nameFont.pointSize];

    _extensionFont = self.extension.font;
    _boldExtensionFont = [UIFont fontWithDescriptor:[[_extensionFont fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:_extensionFont.pointSize];
    
    _numberFont = self.number.font;
    _boldNumberFont = [UIFont fontWithDescriptor:[[_numberFont fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:_numberFont.pointSize];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.date.text = self.recentEvent.formattedModifiedShortDate;
    self.name.text = self.recentEvent.displayName;
    self.number.text = [NSString stringWithFormat:@"%@ %@ %@", self.recentEvent.displayNumber, NSLocalizedString(@"on", @"on"), self.recentEvent.line.pbx.name];
    
    if (self.recentEvent.isRead)
    {
        self.date.font = _dateFont;
        self.name.font = _nameFont;
        self.number.font = _numberFont;
        self.extension.font = _extensionFont;
    }
    else
    {
        self.date.font = _boldDateFont;
        self.name.font = _boldNameFont;
        self.number.font = _boldNumberFont;
        self.extension.font = _boldExtensionFont;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"read"]) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
    else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    
    if (_recentEvent) {
        [_recentEvent removeObserver:self forKeyPath:@"read"];
        _recentEvent = nil;
    }
}

-(void)dealloc
{
    if (_recentEvent) {
        [_recentEvent removeObserver:self forKeyPath:@"read"];
        _recentEvent = nil;
    }
}

#pragma mark - Setters -

-(void)setRecentEvent:(RecentEvent *)recentEvent
{
    if (_recentEvent) {
        [_recentEvent removeObserver:self forKeyPath:@"read"];
    }
    
    _recentEvent = recentEvent;
    Contact *contact = recentEvent.contact;
    if (contact) {
        self.identifier = contact.jrn;
    }
    
    if (_recentEvent) {
        [_recentEvent addObserver:self forKeyPath:@"read" options:NSKeyValueObservingOptionNew context:NULL];
    }
}

@end
