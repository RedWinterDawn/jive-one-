//
//  JCContactPhoneNumberViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 6/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCustomCell.h"

#import "PhoneNumber.h"

@protocol JCContactPhoneNumberTableViewCellDelegate;

@interface JCContactPhoneNumberTableViewCell : JCCustomCell <UITextFieldDelegate>

@property (nonatomic, weak) id<JCContactPhoneNumberTableViewCellDelegate> delegate;

@property (nonatomic, strong) id<JCPhoneNumberDataSource> phoneNumber;

@property (nonatomic, strong) IBOutlet UIView *editView;

@property (nonatomic, weak) IBOutlet UILabel *typeSelect;
@property (nonatomic, weak) IBOutlet UITextField *textField;

-(IBAction)selectType:(id)sender;

-(void)setType:(NSString *)type;

@end

@protocol JCContactPhoneNumberTableViewCellDelegate <NSObject>

-(void)selectTypeForContactPhoneNumberCell:(JCContactPhoneNumberTableViewCell *)cell;

@end