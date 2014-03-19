//
//  StatusPanel.h
//  CRMA-Slide
//
//  Created by Eduardo Gueiros on 9/11/13.
//  Copyright (c) 2013 Eduardo Gueiros. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface StatusPanel : UIView

@property (nonatomic, assign) CGFloat percentage;
//@property (nonatomic, strong) UIImageView *thumbImageView;
@property (nonatomic, strong) UIButton *cancelButton;
//@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) NSMutableArray *progressImageViews;
@property (nonatomic, strong) UIActivityIndicatorView *waitingView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *snippetLabel;
@property (nonatomic, assign) id delegate;


- (void)showPanelInView:(UIView *)view;

+ (StatusPanel *)sharedInstance;

- (void)showWithTitle:(NSString*)title snippet:(NSString*)snippet showProgress:(BOOL)progress;
- (void)show;

- (void)done;

- (void)hide;

@end

@protocol ICProgressPanelDelegate <NSObject>

- (void)progressPanelDidFinishLoad:(StatusPanel *)panel;
- (void)progressPanelDidCancelLoad:(StatusPanel *)panel;

@end
