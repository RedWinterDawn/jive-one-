//
//  JCCustomEdit.h
//  JiveOne
//
//  Created by Robert Barclay on 6/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCustomCell.h"

@interface JCCustomEditTableViewCell : JCCustomCell <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UIView *editView;

@property (nonatomic, weak) IBOutlet UILabel *typeSelect;
@property (nonatomic, weak) IBOutlet UITextField *textField;

-(IBAction)selectType:(id)sender;
-(void)setType:(NSString *)type;

@end
