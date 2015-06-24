//
//  JCCustomCell.m
//  JiveOne
//
//  Created by Robert Barclay on 1/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCustomCell.h"

@implementation JCCustomCell


+(instancetype)cellWithParent:(id)parent bundle:(NSBundle *)bundle
{
    NSArray *topLevelObjects = [bundle loadNibNamed:[self cellReuseIdentifier] owner:parent options:nil];
    id cell = [topLevelObjects firstObject];
    if ([cell isKindOfClass:[self class]]) {
        return cell;
    }
    return nil;
}

+ (NSString *)cellReuseIdentifier
{
    return NSStringFromClass([self class]);
}

@synthesize textLabel;
@synthesize detailTextLabel;
@synthesize imageView;

@end
