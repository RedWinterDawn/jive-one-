//
//  JCDialerOptions.m
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDialerOptions.h"

@implementation JCDialerOptions

-(void)layoutSubviews
{
    [super layoutSubviews];
    
}



-(void)setState:(JCDialerOptionState)state
{
    [self setState:state animated:NO];
}

-(void)setState:(JCDialerOptionState)state animated:(bool)animated
{
    switch (state) {
        case JCDialerOptionSingle:
            break;
            
        case JCDialerOptionMultiple:
            break;
          
        case JCDialerOptionConference:
            break;
            
        default:
            break;
    }
}


@end
