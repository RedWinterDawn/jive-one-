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

-(NSString *)name
{
    return NSLocalizedString(kJCVoicemailNumberNameString, nil);
}

-(NSString *)number
{
    return kJCVoicemailNumberString;
}


@end
