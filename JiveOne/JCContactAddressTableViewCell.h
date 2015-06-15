//
//  JCContactAddressTableViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 6/11/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCustomEditTableViewCell.h"
#import "Address.h"

@interface JCContactAddressTableViewCell : JCCustomEditTableViewCell

@property (nonatomic, strong) Address *address;

@property (nonatomic, weak) IBOutlet UILabel *cityLabel;
@property (nonatomic, weak) IBOutlet UITextField *cityTextField;

@property (nonatomic, weak) IBOutlet UILabel *regionLabel;
@property (nonatomic, weak) IBOutlet UITextField *regionTextField;

@property (nonatomic, weak) IBOutlet UILabel *postalCodeLabel;
@property (nonatomic, weak) IBOutlet UITextField *postalCodeTextField;

@end
