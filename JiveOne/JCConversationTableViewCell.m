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
    
    UIColor *_readColor;
    UIColor *_unreadColor;
    
    UIColor *_dateColor;
}

@end

@implementation JCConversationTableViewCell

-(void)awakeFromNib
{
    [super awakeFromNib];
    _readColor      = [UIColor darkGrayColor];
    _unreadColor    = [UIColor blackColor];
    _dateColor      = [UIColor lightGrayColor];
    
    _nameFont       = self.name.font;
    _boldNameFont   = [UIFont fontWithDescriptor:[[_nameFont fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold]
                                            size:_nameFont.pointSize];
    
    _detailFont     = self.detail.font;
    _boldDetailFont = [UIFont fontWithDescriptor:[[_detailFont fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold]
                                            size:_detailFont.pointSize];
    
    _dateFont       = self.date.font;
    _boldDateFont   = [UIFont fontWithDescriptor:[[_dateFont fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold]
                                            size:_dateFont.pointSize];
}

#pragma mark - Setters -

-(void)setRead:(BOOL)read
{
    _read = read;
    UILabel *name   = self.name;
    UILabel *detail = self.detail;
    UILabel *date   = self.date;
    UIView  *unread = self.unreadCircle;
    
    if (self.isRead) {
        name.font           = _nameFont;
        name.textColor      = _readColor;
        detail.font         = _detailFont;
        detail.textColor    = _readColor;
        date.font           = _dateFont;
        date.textColor      = _dateColor;
        unread.hidden       = true;
    } else {
        name.font           = _boldNameFont;
        name.textColor      = _unreadColor;
        detail.font         = _boldDetailFont;
        detail.textColor    = _unreadColor;
        date.font           = _boldDateFont;
        date.textColor      = _unreadColor;
        unread.hidden       = false;
    }
}

-(IBAction)blockNumberBtn:(id)sender
{
    [self.delegate didBlockConverastionTableViewCell:self];
}

@end
