//
//  JCVoiceNonVisualViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoiceNonVisualViewController.h"
#import "JCPhoneManager.h"
#import "JCVoicemailNumber.h"

@implementation JCVoiceNonVisualViewController

-(IBAction)callVoicemail:(id)sender
{
    Line *line = self.authenticationManager.line;
    [self dialNumber:[JCVoicemailNumber new]
           usingLine:line
              sender:sender];
}

@end
