//
//  JCMessagesInputToolbar.m
//  JiveOne
//
//  Created by Robert Barclay on 2/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMessagesInputToolbar.h"
#import <JSQMessagesViewController/UIView+JSQMessages.h>
#import <JSQMessagesViewController/JSQMessagesToolbarButtonFactory.h>

static void * kJSQMessagesInputToolbarKeyValueObservingContext = &kJSQMessagesInputToolbarKeyValueObservingContext;

@protocol JSQMessagesInputToolbarPrivate <NSObject>

@optional
@property (assign, nonatomic) BOOL jsq_isObserving;

- (void)jsq_addObservers;
- (void)jsq_removeObservers;

- (void)jsq_leftBarButtonPressed:(UIButton *)sender;
- (void)jsq_rightBarButtonPressed:(UIButton *)sender;

@end

@interface JCMessagesInputToolbar () <JSQMessagesInputToolbarPrivate>
{
    JCMessagesToolbarContentView *_contentView;
}

@end

@implementation JCMessagesInputToolbar

@synthesize jsq_isObserving = _jsq_isObserving;

- (void)awakeFromNib
{
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    self.jsq_isObserving = NO;
    self.sendButtonOnRight = YES;
    
    JCMessagesToolbarContentView *toolbarContentView = self.contentView;
    toolbarContentView.frame = self.frame;
    [self addSubview:toolbarContentView];
    [self jsq_pinAllEdgesOfSubview:toolbarContentView];
    [self setNeedsUpdateConstraints];
    
    [self jsq_addObservers];
    
    self.contentView.leftBarButtonItem = nil; // [JSQMessagesToolbarButtonFactory defaultAccessoryButtonItem]; // Removed support for the media attachement option.
    self.contentView.rightBarButtonItem = [JSQMessagesToolbarButtonFactory defaultSendButtonItem];
    
    [self toggleSendButtonEnabled];
}

- (void)dealloc {
    [self jsq_removeObservers];
    _contentView = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kJSQMessagesInputToolbarKeyValueObservingContext) {
        if (object == _contentView) {
            
            if ([keyPath isEqualToString:NSStringFromSelector(@selector(leftBarButtonItem))]) {
                
                [_contentView.leftBarButtonItem removeTarget:self
                                                      action:NULL
                                            forControlEvents:UIControlEventTouchUpInside];
                
                [_contentView.leftBarButtonItem addTarget:self
                                                   action:@selector(jsq_leftBarButtonPressed:)
                                         forControlEvents:UIControlEventTouchUpInside];
            }
            else if ([keyPath isEqualToString:NSStringFromSelector(@selector(rightBarButtonItem))]) {
                
                [_contentView.rightBarButtonItem removeTarget:self
                                                       action:NULL
                                             forControlEvents:UIControlEventTouchUpInside];
                
                [_contentView.rightBarButtonItem addTarget:self
                                                    action:@selector(jsq_rightBarButtonPressed:)
                                          forControlEvents:UIControlEventTouchUpInside];
            }
            
            [self toggleSendButtonEnabled];
        }
    }
}

- (void)toggleSendButtonEnabled
{
    BOOL hasText = [self.contentView.textView hasText];
    
    if (self.sendButtonOnRight) {
        self.contentView.rightBarButtonItem.enabled = hasText;
    }
    else {
        self.contentView.leftBarButtonItem.enabled = hasText;
    }
}

#pragma mark - Setters -

-(void)setContentView:(JCMessagesToolbarContentView *)contentView
{
    _contentView = contentView;
}

#pragma mark - Getters -

-(JCMessagesToolbarContentView *)contentView
{
    return _contentView;
}

#pragma mark - Private -

- (void)jsq_addObservers
{
    if (self.jsq_isObserving) {
        return;
    }
    
    [_contentView addObserver:self
                       forKeyPath:NSStringFromSelector(@selector(leftBarButtonItem))
                          options:0
                          context:kJSQMessagesInputToolbarKeyValueObservingContext];
    
    [_contentView addObserver:self
                       forKeyPath:NSStringFromSelector(@selector(rightBarButtonItem))
                          options:0
                          context:kJSQMessagesInputToolbarKeyValueObservingContext];
    
    _jsq_isObserving = YES;
}

- (void)jsq_removeObservers
{
    if (!_jsq_isObserving) {
        return;
    }
    
    @try {
        [_contentView removeObserver:self
                          forKeyPath:NSStringFromSelector(@selector(leftBarButtonItem))
                             context:kJSQMessagesInputToolbarKeyValueObservingContext];
        
        [_contentView removeObserver:self
                          forKeyPath:NSStringFromSelector(@selector(rightBarButtonItem))
                             context:kJSQMessagesInputToolbarKeyValueObservingContext];
    }
    @catch (NSException *__unused exception) { }
    
    _jsq_isObserving = NO;
}

@end
