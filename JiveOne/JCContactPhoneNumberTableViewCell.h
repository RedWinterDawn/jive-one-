//
//  JCContactPhoneNumberViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 6/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCustomEditTableViewCell.h"

#import "PhoneNumber.h"

@class JCContactPhoneNumberTableViewCell;

@protocol JCContactPhoneNumberTableViewCellDelegate <JCCustomEditTableViewCellDelegate>

-(void)contactPhoneNumberCell:(JCContactPhoneNumberTableViewCell *)cell dialPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber;

@end

@interface JCContactPhoneNumberTableViewCell : JCCustomEditTableViewCell

@property (nonatomic, weak) id<JCContactPhoneNumberTableViewCellDelegate> delegate;
@property (nonatomic, strong) id<JCPhoneNumberDataSource> phoneNumber;


-(IBAction)dial:(id)sender;

@end

