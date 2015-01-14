//
//  JCDialerOptions.m
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallOptionsView.h"

#define DIAL_OPTIONS_ANIMATION_DURATION 0.3f

@interface JCCallOptionsView ()
{
    CGFloat _defaultTransferPosition;
    CGFloat _defaultWarmTransferPosition;
    CGFloat _defaultAddCallPosition;
    CGFloat _defaultSwapPosition;
    CGFloat _defaultMergePosition;
    CGFloat _defaultFinishPosition;
    
    bool _showingInital;
    bool _showingSingle;
    bool _showingMultiple;
    bool _showingConference;
    bool _showingFinish;
}

@end

@implementation JCCallOptionsView

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _annimationDuration = DIAL_OPTIONS_ANIMATION_DURATION;
        _showingSingle = false;
        _showingInital = true;
    }
    return self;
}

-(void)awakeFromNib
{
    _defaultTransferPosition        = _transferBtnHorizontalContstraint.constant;
    _defaultWarmTransferPosition    = _warmBtnVerticalConstraint.constant;
    _defaultAddCallPosition         = _addCallBtnHorizontalContstraint.constant;
    _defaultSwapPosition            = _swapBtnHorizontalContstraint.constant;
    _defaultMergePosition           = _mergeBtnHorizontalContstraint.constant;
    _defaultFinishPosition          = _finishTransferConstraint.constant;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    [self showInital:TRUE];
//    [self hideSingle:FALSE completion:NULL];
}

-(void)setState:(JCCallOptionViewState)state
{
    [self setState:state animated:YES];
}

-(void)setState:(JCCallOptionViewState)state animated:(bool)animated
{
    _state = state;
    if (self.superview)
        [self changeState:animated];
}

-(void)changeState:(bool)animated
{
    switch (_state) {
        case JCCallOptionViewMultipleCallsState:
            [self showMultiple:animated];
            break;
            
        case JCCallOptionViewConferenceCallState:
            [self showConference:animated];
            break;
            
        case JCCallOptionViewFinishTransferState:
            [self showFinishTransfer:animated];
            break;
            
        case JCCallOptionViewSingleCallState:
            [self showSingle:animated];
            break;
            
        default:
            [self showInital:animated];
            break;
    }
}

#pragma mark - Inital -

-(void)showInital:(BOOL)animated
{
    if (_showingMultiple)
        [self hideMultiple:animated completion:^(BOOL finished) {
            [self showInital:animated completion:NULL];
        }];
    
    else if (_showingConference)
        [self hideConference:animated completion:^(BOOL finished) {
            [self showInital:animated completion:NULL];
        }];
    
    else if (_showingSingle)
        [self hideSingle:animated completion:^(BOOL finished) {
            [self showInital:animated completion:NULL];
        }];
    
    else if (_showingFinish)
        [self hideFinishTransfer:animated completion:^(BOOL finished) {
            [self showInital:animated completion:NULL];
        }];
}

-(void)showInital:(bool)animated completion:(void (^)(BOOL finished))completion
{
    _transferBtnHorizontalContstraint.constant = - (5 * _defaultTransferPosition);
    _warmBtnVerticalConstraint.constant = - (5 * _defaultWarmTransferPosition);
    _addCallBtnHorizontalContstraint.constant = - (5 * _defaultAddCallPosition);
    
    [self animate:animated completion:^(BOOL finished) {
        _showingInital = true;
        if (completion != NULL && finished)
            completion(finished);
    }];
}

-(void)hideInital:(bool)animated completion:(void (^)(BOOL finished))completion
{
    
    _transferBtnHorizontalContstraint.constant  = _defaultTransferPosition;
    _warmBtnVerticalConstraint.constant         = _defaultWarmTransferPosition;
    _addCallBtnHorizontalContstraint.constant   = _defaultAddCallPosition;
    
    
    
    [self animate:animated completion:^(BOOL finished) {
        _showingInital = false;
        if (completion != NULL && finished)
            completion(finished);
    }];
}


#pragma mark - Single -

-(void)showSingle:(BOOL)animated
{
    if (_showingMultiple)
        [self hideMultiple:animated completion:^(BOOL finished) {
            [self showSingle:animated completion:NULL];
        }];
    
    else if (_showingConference)
        [self hideConference:animated completion:^(BOOL finished) {
            [self showSingle:animated completion:NULL];
        }];

    else if (_showingInital)
        [self hideInital:animated completion:^(BOOL finished) {
            [self showSingle:animated completion:NULL];
        }];

    else if (_showingFinish)
        [self hideFinishTransfer:animated completion:^(BOOL finished) {
            [self showSingle:animated completion:NULL];
        }];
}

-(void)showSingle:(bool)animated completion:(void (^)(BOOL finished))completion
{
    _transferBtnHorizontalContstraint.constant  = _defaultTransferPosition;
    _warmBtnVerticalConstraint.constant         = _defaultWarmTransferPosition;
    _addCallBtnHorizontalContstraint.constant   = _defaultAddCallPosition;
    
    [self animate:animated completion:^(BOOL finished) {
        _showingSingle = true;
        if (completion != NULL && finished)
            completion(finished);
    }];
}

-(void)hideSingle:(bool)animated completion:(void (^)(BOOL finished))completion
{
    _transferBtnHorizontalContstraint.constant = - (5 * _defaultTransferPosition);
    _warmBtnVerticalConstraint.constant = - (5 * _defaultWarmTransferPosition);
    _addCallBtnHorizontalContstraint.constant = - (5 * _defaultAddCallPosition);
    
    [self animate:animated completion:^(BOOL finished) {
        _showingSingle = false;
        if (completion != NULL && finished)
            completion(finished);
    }];
}


#pragma mark - Multiple -

-(void)showMultiple:(BOOL)animated
{
    if (_showingSingle)
        [self hideSingle:animated completion:^(BOOL finished) {
            [self showMultiple:animated completion:NULL];
        }];
    
    else if (_showingConference)
        [self hideConference:animated completion:^(BOOL finished) {
            [self showMultiple:animated completion:NULL];
        }];
    
    else if (_showingInital)
        [self hideInital:animated completion:^(BOOL finished) {
            [self showMultiple:animated completion:NULL];
        }];
    
    else if (_showingFinish)
        [self hideFinishTransfer:animated completion:^(BOOL finished) {
            [self showMultiple:animated completion:NULL];
        }];
}

-(void)showMultiple:(bool)animated completion:(void (^)(BOOL finished))completion
{
    _swapBtnHorizontalContstraint.constant  = - _defaultSwapPosition;
    _mergeBtnHorizontalContstraint.constant = - _defaultMergePosition;
    
    [self animate:animated completion:^(BOOL finished) {
        _showingMultiple = true;
        if (completion != NULL && finished)
            completion(finished);
    }];
}



-(void)hideMultiple:(bool)animated completion:(void (^)(BOOL finished))completion
{
    _swapBtnHorizontalContstraint.constant  = _defaultSwapPosition;
    _mergeBtnHorizontalContstraint.constant = _defaultMergePosition;
    
    [self animate:animated completion:^(BOOL finished) {
        _showingMultiple = false;
        if (completion != NULL && finished)
            completion(finished);
    }];
}

#pragma mark - Conference -

-(void)showConference:(bool)animated
{
    if (_showingSingle)
        [self hideSingle:animated completion:^(BOOL finished) {
            [self showConference:animated completion:NULL];
        }];
    
    else if (_showingMultiple)
        [self hideMultiple:animated completion:^(BOOL finished) {
            [self showConference:animated completion:NULL];
        }];
    
    else if (_showingInital)
        [self hideInital:animated completion:^(BOOL finished) {
            [self showConference:animated completion:NULL];
        }];
    
    else if (_showingFinish)
        [self hideFinishTransfer:animated completion:^(BOOL finished) {
            [self showConference:animated completion:NULL];
        }];
}

-(void)showConference:(bool)animated completion:(void (^)(BOOL finished))completion
{
    _mergeBtnHorizontalContstraint.constant = - _defaultMergePosition;
    _addCallBtnHorizontalContstraint.constant = - _defaultSwapPosition;
    
    [self animate:animated completion:^(BOOL finished) {
        _showingConference = true;
        if (completion != NULL && finished)
            completion(finished);
    }];
}



-(void)hideConference:(bool)animated completion:(void (^)(BOOL finished))completion
{
    _mergeBtnHorizontalContstraint.constant = _defaultMergePosition;
    _addCallBtnHorizontalContstraint.constant = _defaultSwapPosition;
    
    [self animate:animated completion:^(BOOL finished) {
        _showingConference = false;
        if (completion != NULL && finished)
            completion(finished);
    }];
}

#pragma mark - Finish Transfer -

-(void)showFinishTransfer:(bool)animated
{
    if (_showingSingle)
        [self hideSingle:animated completion:^(BOOL finished) {
            [self showFinishTransfer:animated completion:NULL];
        }];
    
    else if (_showingMultiple)
        [self hideMultiple:animated completion:^(BOOL finished) {
            [self showFinishTransfer:animated completion:NULL];
        }];
    
    else if (_showingInital)
        [self hideInital:animated completion:^(BOOL finished) {
            [self showMultiple:animated completion:NULL];
        }];
    
    else if (_showingConference)
        [self hideConference:animated completion:^(BOOL finished) {
            [self showFinishTransfer:animated completion:NULL];
        }];
}

-(void)showFinishTransfer:(bool)animated completion:(void (^)(BOOL finished))completion
{
    _finishTransferConstraint.constant = - (_defaultFinishPosition / 4);
    [self animate:animated completion:^(BOOL finished) {
        _showingFinish = true;
        if (completion != NULL && finished)
            completion(finished);
    }];
}

-(void)hideFinishTransfer:(bool)animated completion:(void (^)(BOOL finished))completion
{
    _finishTransferConstraint.constant = _defaultFinishPosition;
    [self animate:animated completion:^(BOOL finished) {
        _showingFinish = false;
        if (completion != NULL && finished)
            completion(finished);
    }];
}

-(void)animate:(bool)animated completion:(void (^)(BOOL finished))completion
{
    [self needsUpdateConstraints];
    [UIView animateWithDuration:animated ? _annimationDuration : 0
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         if (completion != NULL && finished)
                             completion(finished);
                     }];
}

@end
