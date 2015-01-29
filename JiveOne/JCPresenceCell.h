//
//  JCPresenceCell.h
//  JiveOne
//
//  Created by Robert Barclay on 11/5/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCustomCell.h"

@interface JCPresenceCell : JCCustomCell

@property (nonatomic, strong) NSString *identifier;

@property (nonatomic) NSUInteger lineWidth;
@property (nonatomic) UIColor *baseColor;

@end
