//
//  JCCallCard.m
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardView.h"

@implementation JCCallCardView

-(IBAction)hangup:(id)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(callCardViewShouldHangUp:)])
        [_delegate callCardViewShouldHangUp:self];
}

-(IBAction)placeOnHold:(id)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(callCardViewShouldHold:)])
        [_delegate callCardViewShouldHold:self];
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