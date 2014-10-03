//
//  JCDialerOptions.m
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDialerOptions.h"

#define DIAL_OPTIONS_ANIMATION_DURATION 0.3f

@interface JCDialerOptions ()
{
    CGFloat _defaultTransferPosition;
    CGFloat _defaultWarmTransferPosition;
    CGFloat _defaultAddCallPosition;
    CGFloat _defaultSwapPosition;
    CGFloat _defaultMergePosition;
    
    bool _showingSingle;
    bool _showingMultiple;
}

@end

@implementation JCDialerOptions

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _annimationDuration = DIAL_OPTIONS_ANIMATION_DURATION;
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
}

-(void)layoutSubviews
{
    [super layoutSubviews];
}

-(void)setState:(JCDialerOptionState)state
{
    [self setState:state animated:NO];
}

-(void)setState:(JCDialerOptionState)state animated:(bool)animated
{
    _state = state;
    [self changeState:animated];
}

-(void)changeState:(bool)animated
{
    switch (_state) {
        case JCDialerOptionSingle:
        {
            [self hideMultiple:animated completion:^(BOOL finished) {
                [self showSingle:animated completion:NULL];
            }];
            break;
        }
            
        case JCDialerOptionMultiple:
        {
            [self hideSingle:animated completion:^(BOOL finished) {
                [self showMultiple:animated completion:NULL];
            }];
            break;
        }
            
        case JCDialerOptionConference:
            break;
            
        default:
            break;
    }
}

-(void)showSingle:(bool)animated completion:(void (^)(BOOL finished))completion
{
    _transferBtnHorizontalContstraint.constant  = _defaultTransferPosition;
    _warmBtnVerticalConstraint.constant         = _defaultWarmTransferPosition;
    _addCallBtnHorizontalContstraint.constant   = _defaultAddCallPosition;
    [self needsUpdateConstraints];
    
    [UIView animateWithDuration:animated ? _annimationDuration : 0
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         _showingSingle = true;
                         
                         if (completion != NULL && finished)
                             completion(finished);
                     }];
}

-(void)showMultiple:(bool)animated completion:(void (^)(BOOL finished))completion
{
    _swapBtnHorizontalContstraint.constant  = - _defaultSwapPosition;
    _mergeBtnHorizontalContstraint.constant = - _defaultMergePosition;
    [self needsUpdateConstraints];
    
    [UIView animateWithDuration:animated ? _annimationDuration : 0
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         _showingMultiple = true;
                         if (completion != NULL && finished)
                             completion(finished);
                     }];
}

-(void)hideSingle:(bool)animated completion:(void (^)(BOOL finished))completion
{
    _transferBtnHorizontalContstraint.constant = - (5 * _defaultTransferPosition);
    _warmBtnVerticalConstraint.constant = - (5 * _defaultWarmTransferPosition);
    _addCallBtnHorizontalContstraint.constant = - (5 * _defaultAddCallPosition);
    [self needsUpdateConstraints];
    
    [UIView animateWithDuration:animated ? _annimationDuration : 0
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         _showingSingle = false;
                         if (completion != NULL && finished)
                             completion(finished);
                     }];
}

-(void)hideMultiple:(bool)animated completion:(void (^)(BOOL finished))completion
{
    _swapBtnHorizontalContstraint.constant  = _defaultSwapPosition;
    _mergeBtnHorizontalContstraint.constant = _defaultMergePosition;
    [self needsUpdateConstraints];
    
    [UIView animateWithDuration:animated ? _annimationDuration : 0
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         _showingMultiple = false;
                         if (completion != NULL && finished)
                             completion(finished);
                     }];
}

@end
