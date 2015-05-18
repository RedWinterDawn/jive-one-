//
//  VoicemailTranscription.m
//  JiveOne
//
//  Created by P Leonard on 5/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "VoicemailTranscription.h"
#import "Voicemail.h"
#import "NSManagedObject+Additions.h"

NSString *const kVoicemailTranscriptionConfidenceAttribute = @"confidence";
NSString *const kVoicemailTranscriptionWordCountAttribute = @"wordCount";

@implementation VoicemailTranscription

@dynamic url_self;
@dynamic text;
@dynamic voicemail;

#pragma mark - Setters -
-(void)setConfidence:(float)confidence
{
    [self setPrimitiveValueFromFloatValue:confidence forKey:kVoicemailTranscriptionConfidenceAttribute];
}

-(void)setWordCount:(NSInteger)wordCount
{
    [self setPrimitiveValueFromIntegerValue:wordCount forKey:kVoicemailTranscriptionWordCountAttribute];
}

#pragma mark - Getters -
-(float)confidence
{
    return [self floatValueFromPrimitiveValueForKey:kVoicemailTranscriptionConfidenceAttribute];
}

-(NSInteger)wordCount
{
    return [self integerValueFromPrimitiveValueForKey:kVoicemailTranscriptionWordCountAttribute];
}
@end
