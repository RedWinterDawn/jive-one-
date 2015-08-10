//
//  JCContactCollectionViewCell.m
//  JiveOne
//
//  Created by Robert Barclay on 3/30/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumberCollectionViewCell.h"

@implementation JCPhoneNumberCollectionViewCell

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
}

+ (NSString *)cellReuseIdentifier
{
    return NSStringFromClass([self class]);
}

@end
