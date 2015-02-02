//
//  JCMessageBarView.h
//  JiveOne
//
//  Created by Robert Barclay on 1/29/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPlaceholderTextView.h"
#import "JCView.h"

@class JCMessageBarView;

@protocol JCMessageBarViewDelegate <NSObject>

@optional
- (BOOL)messageBarTextViewShouldBeginEditing:(UITextView *)textView;
- (BOOL)messageBarTextViewShouldEndEditing:(UITextView *)textView;

- (void)messageBarTextViewDidBeginEditing:(UITextView *)textView;
- (void)messageBarTextViewDidEndEditing:(UITextView *)textView;

- (BOOL)messageBarTextView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
- (void)messageBarTextViewDidChange:(UITextView *)textView;

- (void)messageBarTextView:(UITextView *)textView willChangeHeight:(CGFloat)height;
- (void)messageBarTextView:(UITextView *)textView didChangeHeight:(CGFloat)height;

- (void)messageBarTextViewDidChangeSelection:(UITextView *)textView;
//- (BOOL)messageBarTextViewShouldReturn:(UITextView *)textView;

@end

@interface JCMessageBarView : JCView <UITextViewDelegate>

// IBOutlets
@property (nonatomic, weak) IBOutlet JCPlaceholderTextView *textView;
@property (nonatomic, weak) IBOutlet id <JCMessageBarViewDelegate> delegate;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *heightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topMarginConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomMarginConstraint;

// Configurable Properties.
@property (nonatomic) CGFloat maxHeight;
@property (nonatomic) CGFloat minHeight;
@property (nonatomic) BOOL animateHeightChange;
@property (nonatomic) NSTimeInterval animationDuration;
@property (nonatomic) NSInteger maxNumberOfLines;
@property (nonatomic) NSInteger minNumberOfLines;           // Default set to 1

@end
