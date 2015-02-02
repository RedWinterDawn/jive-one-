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

@protocol JSQMessagesInputToolbarPrivate <NSObject>

@optional
@property (assign, nonatomic) BOOL jsq_isObserving;

- (void)jsq_addObservers;
- (void)jsq_removeObservers;

@end

@interface JCMessagesInputToolbar () <JSQMessagesInputToolbarPrivate>

@end

@implementation JCMessagesInputToolbar

@synthesize contentView = _contentView;
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

- (void)jsq_addObservers
{
    if (self.jsq_isObserving) {
        return;
    }
    
    [_contentView addObserver:self
                       forKeyPath:NSStringFromSelector(@selector(leftBarButtonItem))
                          options:0
                          context:nil];
    
    [_contentView addObserver:self
                       forKeyPath:NSStringFromSelector(@selector(rightBarButtonItem))
                          options:0
                          context:nil];
    
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
                             context:nil];
        
        [_contentView removeObserver:self
                          forKeyPath:NSStringFromSelector(@selector(rightBarButtonItem))
                             context:nil];
    }
    @catch (NSException *__unused exception) { }
    
    _jsq_isObserving = NO;
}

@end
