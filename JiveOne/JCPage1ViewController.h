//
//  JCPage1ViewController.h
//  JiveOne
//
//  Created by Doug on 5/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCPageClass.h"

@protocol Page1Delegate;

@interface JCPage1ViewController : JCPageClass <UIScrollViewDelegate>
@property (strong,nonatomic) UIAttachmentBehavior* attachment;
@property (nonatomic) NSInteger index;
@property (weak, nonatomic) IBOutlet UIImageView *voicemailImageView;
@property (weak, nonatomic) IBOutlet UIImageView *moreIconImageView;
@end

@protocol Page1Delegate <NSObject>

- (void)scrollingDidChangePullOffset:(CGFloat)offset;

@end
