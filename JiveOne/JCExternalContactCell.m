//
//  JCExternalContactCell.m
//  JiveOne
//
//  Created by P Leonard on 12/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCExternalContactCell.h"

@implementation JCExternalContactCell

-(void)layoutSubviews
{
    [super layoutSubviews];
    
}

-(void)SetExternalContactName:(NSString *)name{
    self.externalNameLabel.text = name;
}
-(void)SetExternalContactNumber:(NSString *)number{
    self.externalNumberLebel.text = number;
}
-(void)SetExternalface:(UIImage *)face{
    self.externalImage.image = face;
}

@end
