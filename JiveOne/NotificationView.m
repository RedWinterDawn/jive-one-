//
//  StatusPanel.m
//
//  Created by Eduardo Gueiros on 9/11/13.
//  Copyright (c) 2013 Eduardo Gueiros. All rights reserved.
//

#import "NotificationView.h"

@implementation NotificationView

CGFloat panelHeight = 44;
CGFloat panelWidth = 320;

- (id)init {
    if (self = [super init]) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDidChangeStatusBarOrientationNotification:)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
        
        panelWidth = [UIScreen mainScreen].bounds.size.width;
        
        
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
               
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
        _titleLabel.font = [UIFont systemFontOfSize:17.0f];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = [UIColor whiteColor];
        
        _snippetLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
        _snippetLabel.font = [UIFont systemFontOfSize:12.0f];
        _snippetLabel.backgroundColor = [UIColor clearColor];
        _snippetLabel.textColor = [UIColor whiteColor];
        
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7]; /*#000000*/
              
        _waitingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self.waitingView sizeToFit];
        [self refreshView];
        [self addSubview: self.waitingView];
        [self hide];
    }
    return self;
}

- (void)handleDidChangeStatusBarOrientationNotification:(NSNotification *)notification;
{
    // Do something interesting
    NSLog(@"The orientation is %@", [notification.userInfo objectForKey: UIApplicationStatusBarOrientationUserInfoKey]);
    
    [self refreshView];
    
    [self show];
}

-(void)refreshView
{
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if(UIInterfaceOrientationIsPortrait(interfaceOrientation)){
        panelWidth = [UIScreen mainScreen].bounds.size.width;
    }else if(UIInterfaceOrientationIsLandscape(interfaceOrientation)){
        panelWidth = [UIScreen mainScreen].bounds.size.height;
    }
    
    // update controls
    _titleLabel.center = CGPointMake(panelWidth / 2, (panelHeight / 2) - 12);
    _snippetLabel.center = CGPointMake(panelWidth / 2, (panelHeight / 2) + 10);
    self.cancelButton.center = CGPointMake(panelWidth - 18, panelHeight / 2);
    self.waitingView.center = CGPointMake(24, panelHeight / 2);
}

#pragma mark - public

- (BOOL)isLoading {
    return self.percentage > 0 && self.percentage < 1;
}

- (void)showWithTitle:(NSString*)title snippet:(NSString*)snippet showProgress:(BOOL)progress
{
    _titleLabel.text = title;
    _snippetLabel.text = snippet;
    _waitingView.hidden = !progress;
    if(progress)
        [_waitingView startAnimating];
    else
        [_waitingView stopAnimating];
    
    [self show];
}

- (void)show {
    
    
    self.frame = CGRectMake(0, panelHeight + 20, panelWidth, panelHeight);
    CATransition *transition = [CATransition animation];
    transition.duration = 0.75;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromBottom;
    [self.layer addAnimation:transition forKey:nil];
}

- (void)done {
    
    self.cancelButton.hidden = YES;
//    self.doneButton.hidden = NO;
    [self.waitingView stopAnimating];
    
    [self performSelector:@selector(hide) withObject:nil afterDelay:1];
}

+ (NotificationView *)sharedInstance {
    static dispatch_once_t pred;
    __strong static NotificationView *sharedOverlay = nil;
    
    dispatch_once(&pred, ^{
        sharedOverlay = [[NotificationView alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:sharedOverlay selector:@selector(didChangeConnection:) name:AFNetworkingReachabilityDidChangeNotification  object:nil];
    });
    
    return sharedOverlay;
}


#pragma mark - Reachability
- (void)didChangeConnection:(NSNotification *)notification
{
    AFNetworkReachabilityStatus status = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
    switch (status) {
        case AFNetworkReachabilityStatusNotReachable:
            [self showWithTitle:NSLocalizedString(@"No Connection", @"No Connection") snippet:NSLocalizedString(@"please vefify your internet connection", @"please verify your internet connection") showProgress:NO];
            break;
        case AFNetworkReachabilityStatusReachableViaWiFi:
            NSLog(@"WIFI");
            [self hide];
            break;
        case AFNetworkReachabilityStatusReachableViaWWAN:
            NSLog(@"3G");
            [self hide];
            break;
        default:
            NSLog(@"Unkown network status");
            break;
            
            [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    }
}

- (void)cancelUpload:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(progressPanelDidCancelLoad:)]) {
        [_delegate progressPanelDidCancelLoad:self];
    }
    [self hide];
}

- (void)finishUpload:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(progressPanelDidFinishLoad:)]) {
        [_delegate progressPanelDidFinishLoad:self];
    }
}

- (void)showPanelInView:(UIView *)view {
    
    [self.cancelButton addTarget:self action:@selector(cancelUpload:) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.hidden = NO;
    
    [self.cancelButton setImage:[UIImage imageNamed:@"close_notification"] forState:UIControlStateNormal];
    [self.cancelButton sizeToFit];
    self.cancelButton.center = CGPointMake(panelWidth - 18, panelHeight / 2);
    [self addSubview:self.cancelButton];
    
    self.titleLabel.text = @"this is the title";
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.titleLabel];
    
    self.snippetLabel.text = @"this is the snippet";
    self.snippetLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.snippetLabel];

    self.waitingView.center = CGPointMake(24, panelHeight / 2);
    [_waitingView startAnimating];

   [view addSubview:self];
}

- (void)hide {
    [_waitingView stopAnimating];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    CATransition *transition = [CATransition animation];
    transition.duration = 0.75;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromTop;
    [self.layer addAnimation:transition forKey:nil];
    self.frame = CGRectMake(0, -panelHeight * 2, panelWidth, panelHeight);
}


@end
