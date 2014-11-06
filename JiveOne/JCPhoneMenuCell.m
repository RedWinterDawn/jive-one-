//
//  JCPhoneMenuCell.m
//  JiveOne
//
//  Created by Robert Barclay on 11/5/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneMenuCell.h"
#import "JCBadgeManager.h"

@interface JCPhoneMenuCell ()
{
    JCBadgeViewStyle *_missedCallDefaultStyle;
    JCBadgeViewStyle *_missedCallDisabledStyle;
    JCBadgeViewStyle *_voicemailDefaultStyle;
    JCBadgeViewStyle *_voicemailDisabledStyle;
}

@end


@implementation JCPhoneMenuCell

// Since overwritting build in properties, need to synthsize
@synthesize textLabel;
@synthesize imageView;

-(void)awakeFromNib
{
    JCBadgeManager *badgeManager = [JCBadgeManager sharedManager];
    [badgeManager addObserver:self forKeyPath:@"voicemails" options:NSKeyValueObservingOptionNew context:NULL];
    [badgeManager addObserver:self forKeyPath:@"missedCalls" options:NSKeyValueObservingOptionNew context:NULL];
    
    _missedCallDefaultStyle = self.missedCallsBadgeView.badgeStyle;
    _voicemailDefaultStyle = self.voicemailsBadgeView.badgeStyle;
    
    _missedCallDisabledStyle = [_missedCallDefaultStyle copy];
    _missedCallDisabledStyle.badgeInsetColor = [UIColor lightGrayColor];
    
    _voicemailDisabledStyle = [_missedCallDisabledStyle copy];
    _voicemailDisabledStyle.badgeInsetColor = _missedCallDisabledStyle.badgeInsetColor;
}


-(void)dealloc
{
    JCBadgeManager *badgeManager = [JCBadgeManager sharedManager];
    [badgeManager removeObserver:self forKeyPath:@"voicemails"];
    [badgeManager removeObserver:self forKeyPath:@"missedCalls"];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    JCBadgeManager *badgeManager = [JCBadgeManager sharedManager];
    
    // Missed Calls
    NSUInteger missedCalls = badgeManager.missedCalls;
    if (missedCalls > 0) {
        self.missedCallsBadgeView.badgeStyle = _missedCallDefaultStyle;
    }
    else {
        self.missedCallsBadgeView.badgeStyle = _missedCallDisabledStyle;
    }
    self.missedCallsBadgeView.badgeText = [NSString stringWithFormat:@"%lu", (unsigned long)badgeManager.missedCalls];
    
    // Voicemails
    NSUInteger voicemails = badgeManager.voicemails;
    if (voicemails > 0) {
        self.voicemailsBadgeView.badgeStyle = _voicemailDefaultStyle;
    }
    else {
        self.voicemailsBadgeView.badgeStyle = _voicemailDisabledStyle;
    }
    self.voicemailsBadgeView.badgeText = [NSString stringWithFormat:@"%lu", (unsigned long)badgeManager.voicemails];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"voicemails"] || [keyPath isEqualToString:@"missedCalls"]) {
        [self setNeedsLayout];
        [self setNeedsUpdateConstraints];
    }
}

@end
