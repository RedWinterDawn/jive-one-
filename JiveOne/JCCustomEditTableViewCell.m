//
//  JCCustomEdit.m
//  JiveOne
//
//  Created by Robert Barclay on 6/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCustomEditTableViewCell.h"

@implementation JCCustomEditTableViewCell

-(void)awakeFromNib
{
    self.textField.enabled = self.editing;
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

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    UIView *editView = self.editView;
    UIView *contentView = self.contentView;
    if (self.isEditing) {
        if (editView.superview == nil) {
            [contentView addSubview:editView];
            editView.frame = contentView.bounds;
        }
    } else {
        [editView removeFromSuperview];
    }
}


@end
