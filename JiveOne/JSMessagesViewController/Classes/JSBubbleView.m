//
//  Created by Jesse Squires
//  http://www.hexedbits.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSMessagesViewController
//
//
//  The MIT License
//  Copyright (c) 2013 Jesse Squires
//  http://opensource.org/licenses/MIT
//

#import "JSBubbleView.h"

#import "JSMessageInputView.h"
#import "JSAvatarImageFactory.h"
#import "NSString+JSMessagesView.h"

#define kMarginTop 14.0f
#define kMarginBottom 6.0f
#define kPaddingTop 6.0f
#define kPaddingBottom 14.0f
#define kBubblePaddingRight 35.0f


@interface JSBubbleView()

- (void)setup;

- (void)addTextViewObservers;
- (void)removeTextViewObservers;

+ (CGSize)textSizeForText:(NSString *)txt;
+ (CGSize)neededSizeForText:(NSString *)text;
+ (CGFloat)neededHeightForText:(NSString *)text;

@end


@implementation JSBubbleView

@synthesize font = _font;

#pragma mark - Setup

- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame
                   bubbleType:(JSBubbleMessageType)bubleType
              bubbleImageView:(UIImageView *)bubbleImageView
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
        
        _type = bubleType;
        
        bubbleImageView.userInteractionEnabled = YES;
        [self addSubview:bubbleImageView];
        _bubbleImageView = bubbleImageView;
        
        UITextView *textView = [[UITextView alloc] init];
        textView.font = [UIFont systemFontOfSize:16.0f];
        textView.textColor = [UIColor blackColor];
        textView.editable = NO;
        textView.userInteractionEnabled = YES;
        textView.showsHorizontalScrollIndicator = NO;
        textView.showsVerticalScrollIndicator = NO;
        textView.scrollEnabled = NO;
        textView.backgroundColor = [UIColor clearColor];
        textView.contentInset = UIEdgeInsetsZero;
        textView.scrollIndicatorInsets = UIEdgeInsetsZero;
        textView.contentOffset = CGPointZero;
        [self addSubview:textView];
        [self bringSubviewToFront:textView];
        _textView = textView;
        
        
        UITextView *senderTextView = [[UITextView alloc] init];
        senderTextView.font = [UIFont systemFontOfSize:9.0f];
        senderTextView.textColor = [UIColor lightGrayColor];
        senderTextView.editable = NO;
        senderTextView.userInteractionEnabled = NO;
        senderTextView.showsHorizontalScrollIndicator = NO;
        senderTextView.showsVerticalScrollIndicator = NO;
        senderTextView.scrollEnabled = NO;
        senderTextView.backgroundColor = [UIColor clearColor];
        senderTextView.contentInset = UIEdgeInsetsZero;
        senderTextView.scrollIndicatorInsets = UIEdgeInsetsZero;
        senderTextView.contentOffset = CGPointZero;
        [self addSubview:senderTextView];
        [self bringSubviewToFront:senderTextView];
        _textViewSender = senderTextView;
        
        if ([_textView respondsToSelector:@selector(textContainerInset)]) {
            _textView.textContainerInset = UIEdgeInsetsMake(8.0f, 4.0f, 2.0f, 4.0f);
        }
        
        if ([_textViewSender respondsToSelector:@selector(textContainerInset)]) {
            _textViewSender.textContainerInset = UIEdgeInsetsMake(8.0f, 4.0f, 2.0f, 4.0f);
        }
        
        [self addTextViewObservers];
        
//        NOTE: TODO: textView frame & text inset
//        --------------------
//        future implementation for textView frame
//        in layoutSubviews : "self.textView.frame = textFrame;" is not needed
//        when setting the property : "_textView.textContainerInset = UIEdgeInsetsZero;"
//        unfortunately, this API is available in iOS 7.0+
//        update after dropping support for iOS 6.0
//        --------------------
    }
    return self;
}

- (void)dealloc
{
    [self removeTextViewObservers];
    _bubbleImageView = nil;
    _textView = nil;
}

#pragma mark - KVO

- (void)addTextViewObservers
{
    [_textView addObserver:self
                forKeyPath:@"text"
                   options:NSKeyValueObservingOptionNew
                   context:nil];
    
    [_textView addObserver:self
                forKeyPath:@"font"
                   options:NSKeyValueObservingOptionNew
                   context:nil];
    
    [_textView addObserver:self
                forKeyPath:@"textColor"
                   options:NSKeyValueObservingOptionNew
                   context:nil];
    [_textViewSender addObserver:self
                      forKeyPath:@"text"
                         options:NSKeyValueObservingOptionNew
                         context:nil];
}

- (void)removeTextViewObservers
{
    [_textView removeObserver:self forKeyPath:@"text"];
    [_textView removeObserver:self forKeyPath:@"font"];
    [_textView removeObserver:self forKeyPath:@"textColor"];
    [_textViewSender removeObserver:self forKeyPath:@"text"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == self.textView || object == self.textViewSender) {
        if ([keyPath isEqualToString:@"text"]
           || [keyPath isEqualToString:@"font"]
           || [keyPath isEqualToString:@"textColor"]) {
            [self setNeedsLayout];
        }
    }
}

#pragma mark - Setters

- (void)setFont:(UIFont *)font
{
    _font = font;
    _textView.font = font;
}

#pragma mark - UIAppearance Getters

- (UIFont *)font
{
    if (_font == nil) {
        _font = [[[self class] appearance] font];
    }
    
    if (_font != nil) {
        return _font;
    }
    
    return [UIFont systemFontOfSize:16.0f];
}

#pragma mark - Getters

- (CGRect)bubbleFrame
{
    CGSize bubbleSizeForMessage = [JSBubbleView neededSizeForText:self.textView.text];
    CGSize bubbleSizeForSender = [JSBubbleView neededSizeForText:self.textViewSender.text];
    
    float width = MAX(bubbleSizeForMessage.width, bubbleSizeForSender.width);
    float height = MAX(bubbleSizeForMessage.height, bubbleSizeForSender.height);
    
    CGSize selected = CGSizeMake(width, height);
    
    CGRect rect = CGRectMake((self.type == JSBubbleMessageTypeOutgoing ? self.frame.size.width - selected.width : 0.0f),
                             kMarginTop,
                             selected.width,
                             selected.height + kMarginTop);
    
    return CGRectIntegral(rect);
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.bubbleImageView.frame = [self bubbleFrame];
    
    CGFloat textX = self.bubbleImageView.frame.origin.x;
    
    if (self.type == JSBubbleMessageTypeIncoming) {
        textX += (self.bubbleImageView.image.capInsets.left / 2.0f);
    }
    
    CGRect textFrame = CGRectMake(textX,
                                  self.bubbleImageView.frame.origin.y,
                                  self.bubbleImageView.frame.size.width - (self.bubbleImageView.image.capInsets.right / 2.0f),
                                  self.bubbleImageView.frame.size.height - kMarginTop);
    
    self.textView.frame = CGRectIntegral(textFrame);

    CGRect senderTextFrame = CGRectMake(textX,
                                        self.textView.frame.size.height, self.bubbleImageView.frame.size.width - (self.bubbleImageView.image.capInsets.right / 2.0f),
                                        20);
    
    self.textViewSender.frame =CGRectIntegral(senderTextFrame);
}

#pragma mark - Bubble view

+ (CGSize)textSizeForText:(NSString *)txt
{
    CGFloat maxWidth = [UIScreen mainScreen].applicationFrame.size.width * 0.70f;
    CGFloat maxHeight = MAX([JSMessageTextView numberOfLinesForMessage:txt],
                         [txt js_numberOfLines]) * [JSMessageInputView textViewLineHeight];
    maxHeight += kJSAvatarImageSize;
    
    CGSize stringSize;
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_0) {
        CGRect stringRect = [txt boundingRectWithSize:CGSizeMake(maxWidth, maxHeight)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{ NSFontAttributeName : [[JSBubbleView appearance] font] }
                                              context:nil];
        
        stringSize = CGRectIntegral(stringRect).size;
    }
    else {
        stringSize = [txt sizeWithFont:[[JSBubbleView appearance] font]
                     constrainedToSize:CGSizeMake(maxWidth, maxHeight)];
    }
    
    return CGSizeMake(roundf(stringSize.width), roundf(stringSize.height));
}

+ (CGSize)neededSizeForText:(NSString *)text
{
    CGSize textSize = [JSBubbleView textSizeForText:text];
    
	return CGSizeMake(textSize.width + kBubblePaddingRight,
                      textSize.height + kPaddingTop + kPaddingBottom);
}

+ (CGFloat)neededHeightForText:(NSString *)text
{
    CGSize size = [JSBubbleView neededSizeForText:text];
    return size.height + kMarginTop + kMarginBottom;
}

@end