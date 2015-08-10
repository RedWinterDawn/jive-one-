//
//  JCConferenceCallCardViewCell.m
//  JiveOne
//
//  Created by Robert Barclay on 1/19/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneConferenceCallCollectionViewCell.h"

@implementation JCPhoneConferenceCallCollectionViewCell

@dynamic callCard;

-(void)setCallCard:(JCPhoneConferenceCall *)callCard
{
    [super setCallCard:callCard];
    NSArray *calls = callCard.calls;
    for (JCPhoneCall *call in calls) {
        if (call.lineSession) {
            [call.lineSession addObserver:self forKeyPath:kJCPhoneSipSessionStateKey options:0 context:NULL];
            [call.lineSession addObserver:self forKeyPath:kJCPhoneSipSessionHoldKey options:0 context:NULL];
        }
    }
    
    [self startTimer];
    
}

-(IBAction)toggleHold:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.enabled = FALSE;
        if (((JCPhoneConferenceCall *)_callCard).isHolding) {
            [_callCard unholdCall:^(BOOL success, NSError *error) {
                button.enabled = TRUE;
            }];
        }
        else {
            [_callCard holdCall:^(BOOL success, NSError *error) {
                button.enabled = TRUE;
            }];
        }
    }
}

-(void)removeObservers
{
    if (_callCard) {
        @try {
            JCPhoneConferenceCall *conferenceCallCard = (JCPhoneConferenceCall *)_callCard;
            NSArray *calls = conferenceCallCard.calls;
            for (JCPhoneCall *call in calls) {
                if (call.lineSession) {
                    [call.lineSession removeObserver:self forKeyPath:kJCPhoneSipSessionStateKey];
                    [call.lineSession removeObserver:self forKeyPath:kJCPhoneSipSessionHoldKey];
                }
            }
        }
        @catch (NSException *exception) {
            
        }
    }
}

-(void)updateState:(BOOL)animated
{
    if (_holdTimer)
    {
        [_holdTimer invalidate];
        _holdTimer = nil;
    }
    
    self.holding = ((JCPhoneConferenceCall *)_callCard).isHolding;
    [self showHoldButton:YES];
}

@end
