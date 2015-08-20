//
//  JCCustomEdit.m
//  JiveOne
//
//  This is a custom class that extends the built in editing behavior to show and hide a edit view
//  that could contain a different layout than the non editing state.
//
//  Created by Robert Barclay on 6/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCustomEditTableViewCell.h"
#import <JCPhoneModule/JCDrawing.h>

@implementation JCCustomEditTableViewCell

-(void)awakeFromNib
{
    BOOL editing = self.editing;
    self.textField.enabled = editing;
    self.detailEditLabel.enabled = editing;

}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    self.textField.enabled = editing;
    self.detailEditLabel.enabled = editing;
}

-(void)setEditing:(BOOL)editing
{
    [super setEditing:editing];
    self.textField.enabled = editing;
    self.detailEditLabel.enabled = editing;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    UIView *editView = self.editView;
    UIView *contentView = self.contentView;
    if (self.isEditing) {
        if (editView.superview == nil) {
            [contentView addSubview:editView];
            CGRect bounds = contentView.bounds;
            bounds.size.height -= 1;
            editView.frame = bounds;
        }
    } else {
        [editView removeFromSuperview];
    }
    
}

-(IBAction)editDetail:(id)sender
{
   [self.delegate selectTypeForCell:self];
}

-(IBAction)textFieldValueChanged:(id)sender
{
    if ([sender isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)sender;
        [self setText:textField.text];
    }
}

-(void)setText:(NSString *)string
{
    NSLog(@"Set text called.");
}


@end
