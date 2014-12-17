//
//  JCVoicemailCell.m
//  JiveOne
//
//  Created by Robert Barclay on 10/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailCell.h"
#import "PBX.h"
#import "Common.h"

@implementation JCVoicemailCell

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.extension.text = self.voicemail.displayExtension;
    self.duration.text = self.voicemail.displayDuration;
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
    _voicemail = voicemail;
    super.recentEvent = voicemail;
}

@end
