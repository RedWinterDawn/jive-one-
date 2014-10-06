//
//  JCCallCard.m
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardView.h"
#import "SipHandler.h"

@implementation JCCallCardView

-(IBAction)hangup:(id)sender
{
	[[SipHandler sharedHandler] hangUpCall];
    if (_delegate && [_delegate respondsToSelector:@selector(callCardViewShouldHangUp:)])
        [_delegate callCardViewShouldHangUp:self];
}

-(IBAction)placeOnHold:(id)sender
{
	[[SipHandler sharedHandler] toggleHoldForCallWithSessionState];
    if (_delegate && [_delegate respondsToSelector:@selector(callCardViewShouldHold:)])
        [_delegate callCardViewShouldHold:self];
}

-(void)setLineSession:(JCLineSession *)lineSession
{
	lineSession.delegate = self;
	self.callTitle.text = lineSession.callTitle;
	self.callDetail.text = lineSession.callDetail;
}

#pragma mark - LineSession delegate
- (void)callStateDidChange:(long)sessionId callState:(JCCall)callState
{
	switch (callState) {
	  case JCCallCanceled:
				[self hangup:nil];
				break;
				
	  default:
				break;
		}
}

@end


NSString *const kJCCallCardViewNibName = @"CallCard";

@implementation JCCallCardView (NibLoading)

+(JCCallCardView *)createCallCardWithIdentifier:(NSString *)identifier  delegate:(id<JCCallCardViewDelegate>)delegate
{
    JCCallCardView *callCard = (JCCallCardView *)[[[NSBundle mainBundle] loadNibNamed:kJCCallCardViewNibName owner:self options:nil] objectAtIndex:0];
    
    callCard.delegate = delegate;
    callCard.identifer = identifier;
    
    return callCard;
}

@end