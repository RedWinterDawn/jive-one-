//
//  Voicemail.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Voicemail.h"
#import "Lines.h"
#import "PBX.h"
#import "Common.h"

@implementation Voicemail

@dynamic markForDeletion;
@dynamic duration;
@dynamic jrn;
@dynamic mailboxUrl;
@dynamic read;
@dynamic transcription;
@dynamic transcriptionPercent;
@dynamic url_changeStatus;
@dynamic url_download;
@dynamic url_pbx;
@dynamic url_self;
@dynamic voicemail;
@dynamic voicemailId;

-(NSString *)displayExtension
{
    if (self.transcription)
        return self.transcription;
    
    NSString *extension = self.number;
    Lines *mailbox = [Lines MR_findFirstByAttribute:@"mailboxUrl" withValue:self.mailboxUrl];
    if (mailbox)
    {
        PBX *pbx = [PBX MR_findFirstByAttribute:@"pbxId" withValue:mailbox.pbxId];
        if (pbx) {
            if ([Common stringIsNilOrEmpty:pbx.name]) {
                extension = [NSString stringWithFormat:@"%@ on %@", mailbox.externsionNumber, pbx.name];
            }
            else {
                extension = [NSString stringWithFormat:@"%@", mailbox.externsionNumber];
            }
        }
        else {
            extension = [NSString stringWithFormat:@"%@", mailbox.externsionNumber];
        }
    }
    
    if ([Common stringIsNilOrEmpty:extension] || [extension isEqualToString:@"Unknown"]) {
        NSString *regexForNumber = @"<.+?>";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexForNumber options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *matches = [regex matchesInString:self.name options:0 range:NSMakeRange(0, [self.name length])];
        
        if (matches.count > 0) {
            NSString *callerNumber = [self.name substringWithRange:[matches[0] range]];
            callerNumber = [callerNumber stringByReplacingOccurrencesOfString:@"<" withString:@""];
            callerNumber = [callerNumber stringByReplacingOccurrencesOfString:@">" withString:@""];
            extension = callerNumber;
        }
    }
    return extension;
}

-(NSString *)displayDuration
{
    return  [NSString stringWithFormat:@"%d:%02d", self.duration.integerValue / 60, self.duration.integerValue % 60, nil];
}

@end
