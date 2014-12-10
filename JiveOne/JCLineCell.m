//
//  JCLineCell.m
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLineCell.h"

@implementation JCLineCell

-(void)setLine:(Line *)line
{
    _line = line;
    self.person = line;
}

@end
