//
//  JCEditableTableViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 6/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCustomCell.h"

@interface JCEditableTableViewCell : JCCustomCell

@property (nonatomic, weak) IBOutlet UITextField *textField;

@end
