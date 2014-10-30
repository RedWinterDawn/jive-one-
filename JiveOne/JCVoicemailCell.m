//
//  JCVoicemailCell.m
//  JiveOne
//
//  Created by Robert Barclay on 10/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailCell.h"
#import "Lines.h"
#import "PBX.h"
#import "Common.h"

@implementation JCVoicemailCell

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    Voicemail *voicemail = self.voicemail;
    
    self.callerIdLabel.text = [voicemail.callerId stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    if (![voicemail.callerId isEqualToString:voicemail.callerIdNumber]) {
        self.callerNumberLabel.text = voicemail.callerIdNumber;
    }else{
        self.callerNumberLabel.text = @"";
    }
    
    if (voicemail.transcription) {
        self.extensionLabel.text = voicemail.transcription;
    }
    else {
        //set extension label with mailbox extension
        NSString *detailText = voicemail.callerIdNumber;
        Lines *mailbox = [Lines MR_findFirstByAttribute:@"mailboxUrl" withValue:self.voicemail.mailboxUrl];
        if (mailbox) {
            PBX *pbx = [PBX MR_findFirstByAttribute:@"pbxId" withValue:mailbox.pbxId];
            if (pbx) {
                if ([Common stringIsNilOrEmpty:pbx.name]) {
                    detailText = [NSString stringWithFormat:@"%@ on %@", mailbox.externsionNumber, pbx.name];
                }
                else {
                    detailText = [NSString stringWithFormat:@"%@", mailbox.externsionNumber];
                }
            }
            else {
                detailText = [NSString stringWithFormat:@"%@", mailbox.externsionNumber];
            }
        }
        self.extensionLabel.text = detailText;
    }
    
    [self doubleCheckNamesAndNumbersForVoicemail:voicemail];
}

#pragma mark - Setters -

-(void)setRecentEvent:(RecentEvent *)recentEvent
{
    if ([recentEvent isKindOfClass:[Voicemail class]])
    {
        self.voicemail = (Voicemail *)recentEvent;
    }
}

-(void)setVoicemail:(Voicemail *)voicemail
{
    super.recentEvent = voicemail;
}

-(Voicemail *)voicemail
{
    return (Voicemail *)super.recentEvent;
}

#pragma mark - Private -

- (void)doubleCheckNamesAndNumbersForVoicemail:(Voicemail *)voicemail
{
    if ([Common stringIsNilOrEmpty:self.callerIdLabel.text] || [self.callerIdLabel.text isEqualToString:@"Unknown"]) {
        NSString *regexForName = @"\".+?\"";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexForName
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        if ([Common stringIsNilOrEmpty:voicemail.callerId]) {
            return;
        }
        NSArray *matches = [regex matchesInString:voicemail.callerId
                                          options:0
                                            range:NSMakeRange(0, [voicemail.callerId length])];
        
        if (matches.count > 0) {
            NSString *callerName = [voicemail.callerId substringWithRange:[matches[0] range]];
            callerName = [callerName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            self.callerIdLabel.text = callerName;
        }
    }
    
    if ([Common stringIsNilOrEmpty:self.extensionLabel.text] || [self.extensionLabel.text isEqualToString:@"Unknown"]) {
        NSString *regexForNumber = @"<.+?>";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexForNumber
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSArray *matches = [regex matchesInString:voicemail.callerId
                                          options:0
                                            range:NSMakeRange(0, [voicemail.callerId length])];
        
        if (matches.count > 0) {
            NSString *callerNumber = [voicemail.callerId substringWithRange:[matches[0] range]];
            callerNumber = [callerNumber stringByReplacingOccurrencesOfString:@"<" withString:@""];
            callerNumber = [callerNumber stringByReplacingOccurrencesOfString:@">" withString:@""];
            self.extensionLabel.text = callerNumber;
        }
    }
}

@end
