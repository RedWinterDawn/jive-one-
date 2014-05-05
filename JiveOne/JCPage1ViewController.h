//
//  JCPage1ViewController.h
//  JiveOne
//
//  Created by Doug on 5/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol Page1Delegate;

@interface JCPage1ViewController : UIViewController <UIScrollViewDelegate>
@property (strong,nonatomic) UIAttachmentBehavior* attachment;

@end

@protocol Page1Delegate <NSObject>

- (void)scrollingDidChangePullOffset:(CGFloat)offset;

@end
