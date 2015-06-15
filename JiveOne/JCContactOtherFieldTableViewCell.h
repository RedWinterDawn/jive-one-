//
//  JCContactOtherFieldTableViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 6/11/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCustomEditTableViewCell.h"

#import "ContactInfo.h"

@interface JCContactOtherFieldTableViewCell : JCCustomEditTableViewCell

@property (nonatomic, strong) ContactInfo *info;

@end
