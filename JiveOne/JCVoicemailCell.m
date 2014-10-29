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

-(void)setVoicemail:(Voicemail *)voicemail
{
    _voicemail = voicemail;
    
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
    
    [self doubleCheckNamesAndNumbers];
}


#pragma mark - Private -

- (void)doubleCheckNamesAndNumbers
{
    if ([Common stringIsNilOrEmpty:self.callerIdLabel.text] || [self.callerIdLabel.text isEqualToString:@"Unknown"]) {
        NSString *regexForName = @"\".+?\"";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexForName
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        if ([Common stringIsNilOrEmpty:_voicemail.callerId]) {
            return;
        }
        NSArray *matches = [regex matchesInString:_voicemail.callerId
                                          options:0
                                            range:NSMakeRange(0, [_voicemail.callerId length])];
        
        if (matches.count > 0) {
            NSString *callerName = [_voicemail.callerId substringWithRange:[matches[0] range]];
            callerName = [callerName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            self.callerIdLabel.text = callerName;
        }
    }
    
    if ([Common stringIsNilOrEmpty:self.extensionLabel.text] || [self.extensionLabel.text isEqualToString:@"Unknown"]) {
        NSString *regexForNumber = @"<.+?>";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexForNumber
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSArray *matches = [regex matchesInString:_voicemail.callerId
                                          options:0
                                            range:NSMakeRange(0, [_voicemail.callerId length])];
        
        if (matches.count > 0) {
            NSString *callerNumber = [_voicemail.callerId substringWithRange:[matches[0] range]];
            callerNumber = [callerNumber stringByReplacingOccurrencesOfString:@"<" withString:@""];
            callerNumber = [callerNumber stringByReplacingOccurrencesOfString:@">" withString:@""];
            self.extensionLabel.text = callerNumber;
        }
    }
}

@end
