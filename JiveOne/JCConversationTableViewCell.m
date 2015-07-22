//
//  JCConversationTableViewCell.m
//  JiveOne
//
//  Created by Robert Barclay on 2/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationTableViewCell.h"
#import "BlockedNumber+V5Client.h"
#import "JCPhoneNumber.h"

@interface JCConversationTableViewCell () {
    UIFont *_nameFont;
    UIFont *_boldNameFont;
    
    UIFont *_detailFont;
    UIFont *_boldDetailFont;
    
    UIFont *_dateFont;
    UIFont *_boldDateFont;
}

@end

@implementation JCConversationTableViewCell

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    _nameFont = self.name.font;
    _boldNameFont = [UIFont fontWithDescriptor:[[_nameFont fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:_nameFont.pointSize];
    
    _detailFont = self.detail.font;
    _boldDetailFont = [UIFont fontWithDescriptor:[[_detailFont fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:_detailFont.pointSize];
    
    _dateFont = self.date.font;
    _boldDateFont = [UIFont fontWithDescriptor:[[_dateFont fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:_dateFont.pointSize];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.isRead) {
        self.name.font      = _nameFont;
        self.detail.font    = _detailFont;
        self.date.font      = _dateFont;
    } else {
        self.name.font      = _boldNameFont;
        self.detail.font    = _boldDetailFont;
        self.date.font      = _boldDateFont;
    }
}

#pragma mark - Setters -

-(void)setRead:(BOOL)read
{
    _read = read;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}
-(UIButton *)blockBtn{
    //make Call to block a number
    return 0;
}

-(IBAction)blockNumberBtn:(id)sender
{
    [self.delegate didBlockConverastionTableViewCell:self];
}

@end
