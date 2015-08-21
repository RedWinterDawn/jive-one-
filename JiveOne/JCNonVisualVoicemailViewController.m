//
//  JCVoiceNonVisualViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCNonVisualVoicemailViewController.h"
#import "JCPhoneManager.h"
#import "JCVoicemailNumber.h"
#import "Line.h"

@implementation JCNonVisualVoicemailViewController

-(IBAction)callVoicemail:(id)sender
{
    [self dialPhoneNumber:[JCVoicemailNumber new]
                   sender:sender];
}

@end
