//
//  JCEditableTableViewCell.m
//  JiveOne
//
//  Created by Robert Barclay on 6/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCEditableTableViewCell.h"

#define CellTextFieldWidth 90.0
#define MarginBetweenControls 20.0

@implementation JCEditableTableViewCell

-(void)awakeFromNib
{
    self.textField.enabled = self.editing;
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    self.textField.enabled = editing;
}

-(void)setEditing:(BOOL)editing
{
    self.textField.enabled = editing;
}

-(BOOL)isEditing
{
    return self.textField.enabled;
}

@end
