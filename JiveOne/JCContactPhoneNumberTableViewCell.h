//
//  JCContactPhoneNumberViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 6/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCustomCell.h"

#import "PhoneNumber.h"

@interface JCContactPhoneNumberTableViewCell : JCCustomCell

@property (nonatomic, strong) PhoneNumber *phoneNumber;

@property (nonatomic, weak) IBOutlet UILabel *typeSelect;
@property (nonatomic, weak) IBOutlet UITextField *textField;

@end
