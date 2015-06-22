//
//  JCCustomEdit.h
//  JiveOne
//
//  Created by Robert Barclay on 6/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCustomCell.h"

@protocol JCCustomEditTableViewCellDelegate;

@interface JCCustomEditTableViewCell : JCCustomCell <UITextFieldDelegate>

@property (nonatomic, weak) id<JCCustomEditTableViewCellDelegate> delegate;

@property (nonatomic, strong) IBOutlet UIView *editView;
@property (nonatomic, weak) IBOutlet UILabel *detailEditLabel;
@property (nonatomic, weak) IBOutlet UITextField *textField;

-(IBAction)editDetail:(id)sender;

-(void)setText:(NSString *)string;

@end

@protocol JCCustomEditTableViewCellDelegate <NSObject>

-(void)selectTypeForCell:(JCCustomEditTableViewCell *)cell;

@end