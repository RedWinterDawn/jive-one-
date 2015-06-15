//
//  JCContactPhoneNumberViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 6/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCustomEditTableViewCell.h"

#import "PhoneNumber.h"

@protocol JCContactPhoneNumberTableViewCellDelegate;

@interface JCContactPhoneNumberTableViewCell : JCCustomEditTableViewCell

@property (nonatomic, weak) id<JCContactPhoneNumberTableViewCellDelegate> delegate;
@property (nonatomic, strong) id<JCPhoneNumberDataSource> phoneNumber;

-(IBAction)dial:(id)sender;

@end

@protocol JCContactPhoneNumberTableViewCellDelegate <NSObject>

-(void)selectTypeForContactPhoneNumberCell:(JCContactPhoneNumberTableViewCell *)cell;
-(void)contactPhoneNumberCell:(JCContactPhoneNumberTableViewCell *)cell dialPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber;

@end