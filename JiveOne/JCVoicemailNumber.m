//
//  JCVoicemailNumber.m
//  JiveOne
//
//  Created by Robert Barclay on 4/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailNumber.h"

NSString *const kJCVoicemailNumberNameString = @"Voicemail";
NSString *const kJCVoicemailNumberString = @"*99";

@implementation JCVoicemailNumber

-(instancetype)init
{
    NSString *name = NSLocalizedString(kJCVoicemailNumberNameString, nil);
    return [super initWithName:name number:kJCVoicemailNumberString];
}

@end
