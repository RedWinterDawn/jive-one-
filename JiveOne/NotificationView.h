//
//  StatusPanel.h
//
//  Created by Eduardo Gueiros on 9/11/13.
//  Copyright (c) 2013 Eduardo Gueiros. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface NotificationView : UIView

@property (nonatomic, assign) CGFloat percentage;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) NSMutableArray *progressImageViews;
@property (nonatomic, strong) UIActivityIndicatorView *waitingView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *snippetLabel;
@property (nonatomic, assign) id delegate;


- (void)showPanelInView:(UIView *)view;

+ (NotificationView *)sharedInstance;

- (void)showWithTitle:(NSString*)title snippet:(NSString*)snippet showProgress:(BOOL)progress;
- (void)show;

- (void)done;

- (void)hide;

@end

@protocol ICProgressPanelDelegate <NSObject>

- (void)progressPanelDidFinishLoad:(NotificationView *)panel;
- (void)progressPanelDidCancelLoad:(NotificationView *)panel;

@end
