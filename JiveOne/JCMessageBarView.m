//
//  JCMessageBarView.m
//  JiveOne
//
//  Created by Robert Barclay on 1/29/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMessageBarView.h"


@implementation JCMessageBarView

#pragma mark - Getters -

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _animateHeightChange = YES;
        _animationDuration = 0.1f;
        
        _minNumberOfLines = 1;
        _maxNumberOfLines = 4;
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    _minHeight = [self heightForNumberOfLines:_minNumberOfLines];
    _maxHeight = [self heightForNumberOfLines:_maxNumberOfLines];
}

#pragma mark - Setters -

-(void)setMaxNumberOfLines:(NSInteger)maxNumberOfLines
{
    _maxNumberOfLines = maxNumberOfLines;
    _maxHeight = [self heightForNumberOfLines:maxNumberOfLines];
}

-(void)setMinNumberOfLines:(NSInteger)minNumberOfLines
{
    _minNumberOfLines = minNumberOfLines;
    _minHeight = [self heightForNumberOfLines:minNumberOfLines];
}

-(void)setMaxHeight:(CGFloat)maxHeight
{
    _maxHeight = maxHeight;
    _maxNumberOfLines = [self numberOfLinesForHeight:_maxHeight];
}

-(void)setMinHeight:(CGFloat)minHeight
{
    _minHeight = minHeight;
    _minNumberOfLines = [self numberOfLinesForHeight:minHeight];
}

#pragma mark - Private -

-(CGFloat)heightForNumberOfLines:(NSInteger)numberOfLines
{
    NSMutableString *string = [NSMutableString stringWithString:@"-"];
    for (NSInteger i = 1; i < numberOfLines; ++i) {
        [string appendString:@"\n|W|"];
    }
    
    UITextView *textView = self.textView;
    CGRect rect = [string boundingRectWithSize:CGSizeMake(textView.bounds.size.width, CGFLOAT_MAX)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:@{NSFontAttributeName: textView.font}
                                        context:nil];
    return rect.size.height;
}

- (NSInteger)numberOfLinesForHeight:(CGFloat)height
{
    CGFloat lineHeight = self.textView.font.lineHeight;
    CGFloat numberOfLines = floor(height / lineHeight);
    return MAX(1, numberOfLines);
}

- (CGFloat)measureCurrentHeight
{
    UITextView *textView = self.textView;
    return ceilf([textView sizeThatFits:textView.frame.size].height);
}


-(void)sizeToFit
{
    CGFloat boundedHeight = MIN(MAX([self measureCurrentHeight], _minHeight), _maxHeight);
    UITextView *textView = self.textView;
    CGFloat height = textView.bounds.size.height;
    
    // Check if we are currently that size that we think we should be. if we are, do nothing, we do
    // not need to resize
    if (height == boundedHeight) {
        return;
    }
    
    // if we are greater than equal to the max height, show the scroll indicators, otherwise they
    // should be hidden
    if (boundedHeight >= _maxHeight) {
        if (!textView.scrollEnabled) {
            textView.scrollEnabled = TRUE;
            [textView flashScrollIndicators];
        }
    }else{
        textView.scrollEnabled = FALSE;
    }
    
    _heightConstraint.constant = boundedHeight + _topMarginConstraint.constant + _bottomMarginConstraint.constant;
    [self setNeedsUpdateConstraints];
    
    if ([_delegate respondsToSelector:@selector(messageBarTextView:willChangeHeight:)]) {
        [_delegate messageBarTextView:textView willChangeHeight:boundedHeight];
    }
    
    [UIView animateWithDuration:_animateHeightChange? _animationDuration : 0
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction| UIViewAnimationOptionBeginFromCurrentState)
                     animations:^(void) {
                         [self layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         if ([_delegate respondsToSelector:@selector(messageBarTextView:didChangeHeight:)]) {
                             [_delegate messageBarTextView:textView didChangeHeight:boundedHeight];
                         }
                     }];
}


#pragma mark - Delegate Handlers -

#pragma mark UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if ([_delegate respondsToSelector:@selector(messageBarTextViewShouldBeginEditing:)]) {
        return [_delegate messageBarTextViewShouldBeginEditing:textView];
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([_delegate respondsToSelector:@selector(messageBarTextViewDidBeginEditing:)]) {
        [_delegate messageBarTextViewDidBeginEditing:textView];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)atext {
    
    //weird 1 pixel bug when clicking backspace when textView is empty
    if(!textView.hasText && [atext isEqualToString:@""])
        return NO;
    
    if ([_delegate respondsToSelector:@selector(messageBarTextView:shouldChangeTextInRange:replacementText:)])
        return [_delegate messageBarTextView:textView shouldChangeTextInRange:range replacementText:atext];
    
    return YES;
}

-(void)textViewDidChange:(JCPlaceholderTextView *)textView
{
    BOOL wasDisplayingPlaceholder = textView.displayPlaceHolder;
    textView.displayPlaceHolder = (textView.text.length == 0);
    if (wasDisplayingPlaceholder != textView.displayPlaceHolder) {
        [textView setNeedsDisplay];
    }
    
    [self sizeToFit];
    
    if ([_delegate respondsToSelector:@selector(messageBarTextViewDidChange:)]) {
        [_delegate messageBarTextViewDidChange:textView];
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    if ([_delegate respondsToSelector:@selector(messageBarTextViewDidChangeSelection:)]) {
        [_delegate messageBarTextViewDidChangeSelection:textView];
    }
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if ([_delegate respondsToSelector:@selector(messageBarTextViewShouldEndEditing:)]) {
        return [_delegate messageBarTextViewShouldEndEditing:textView];
    }
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([_delegate respondsToSelector:@selector(messageBarTextViewDidEndEditing:)]) {
        [_delegate messageBarTextViewDidEndEditing:textView];
    }
}

@end
