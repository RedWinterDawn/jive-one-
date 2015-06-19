//
//  JCConferenceCallCardViewCell.m
//  JiveOne
//
//  Created by Robert Barclay on 1/19/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConferenceCallCardViewCell.h"

@implementation JCConferenceCallCardViewCell

@dynamic callCard;

-(void)setCallCard:(JCConferenceCallCard *)callCard
{
    [super setCallCard:callCard];
    NSArray *calls = callCard.calls;
    for (JCCallCard *call in calls) {
        if (call.lineSession) {
            [call.lineSession addObserver:self forKeyPath:kJCLineSessionStateKey options:0 context:NULL];
            [call.lineSession addObserver:self forKeyPath:kJCLineSessionHoldKey options:0 context:NULL];
        }
    }
    
    [self startTimer];
    
}

-(IBAction)toggleHold:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.enabled = FALSE;
        if (((JCConferenceCallCard *)_callCard).isHolding) {
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
            JCConferenceCallCard *conferenceCallCard = (JCConferenceCallCard *)_callCard;
            NSArray *calls = conferenceCallCard.calls;
            for (JCCallCard *call in calls) {
                if (call.lineSession) {
                    [call.lineSession removeObserver:self forKeyPath:kJCLineSessionStateKey];
                    [call.lineSession removeObserver:self forKeyPath:kJCLineSessionHoldKey];
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
    
    self.holding = ((JCConferenceCallCard *)_callCard).isHolding;
    [self showHoldButton:YES];
}

@end
