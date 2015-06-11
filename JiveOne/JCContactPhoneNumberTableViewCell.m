//
//  JCContactPhoneNumberViewCell.m
//  JiveOne
//
//  Created by Robert Barclay on 6/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCContactPhoneNumberTableViewCell.h"

@implementation JCContactPhoneNumberTableViewCell

static UIFont *firstTextFont = nil;
static UIFont *lastTextFont = nil;

+ (void)initialize
{
    if(self == [self class])
    {
//        firstTextFont = [UIFont systemFontOfSize:20];
//        lastTextFont = [UIFont boldSystemFontOfSize:20];
        // this is a good spot to load any graphics you might be drawing in -drawContentView:
        // just load them and retain them here (ONLY if they're small enough that you don't care about them wasting memory)
        // the idea is to do as LITTLE work (e.g. allocations) in -drawContentView: as possible
    }
}

-(void)awakeFromNib
{
    self.textField.enabled = self.editing;
}

- (void)layoutSubviews
{
    CGRect b = [self bounds];
    b.size.height -= 1; // leave room for the separator line
    b.size.width += 30; // allow extra width to slide for editing
    b.origin.x -= (self.editing && !self.showingDeleteConfirmation) ? 0 : 30; // start 30px left unless editing
    
    [super layoutSubviews];
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.textField.enabled = editing;
}

-(void)setEditing:(BOOL)editing
{
    [super setEditing:editing];
    
    self.textField.enabled = editing;
}

-(BOOL)isEditing
{
    return self.textField.enabled;
}

@end
