//
//  JCVoiceNonVisualViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoiceNonVisualViewController.h"
#import "JCPhoneManager.h"

@implementation JCVoiceNonVisualViewController

-(IBAction)callVoicemail:(id)sender
{
    [self dialNumber:@"*99"
           usingLine:[JCAuthenticationManager sharedInstance].line
              sender:sender];
}

@end
