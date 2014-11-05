//
//  JCRecentEventCell.m
//  JiveOne
//
//  Created by Robert Barclay on 10/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRecentEventCell.h"

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
    self.number.text = self.recentEvent.displayNumber;
    
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

-(void)setRead:(BOOL)read
{
    self.recentEvent.read = read;
    [self setNeedsLayout];
}

@end
