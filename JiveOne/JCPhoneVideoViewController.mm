//
//  VideoViewController.m
//  SIPSample
//
//  Copyright (c) 2013 PortSIP Solutions, Inc. All rights reserved.
//

#import "JCPhoneVideoViewController.h"

@interface JCPhoneVideoViewController () {
    BOOL    isStartVideo;
    BOOL    isInitVideo;
    UIView* viewLocalVideo;
    UIView* viewRemoteVideo;
    long    mSessionId;
}
- (void)checkDisplayVideo;
@end

@implementation JCPhoneVideoViewController

@synthesize viewLocalVideo;
@synthesize viewRemoteVideo;

- (void)checkDisplayVideo
{
    if (isInitVideo) {
        if(isStartVideo)
        {
            [mPortSIPSDK setRemoteVideoWindow:mSessionId remoteVideoWindow:viewRemoteVideo];
            [mPortSIPSDK setLocalVideoWindow:viewLocalVideo];
            [mPortSIPSDK displayLocalVideo:YES];
            [mPortSIPSDK sendVideo:mSessionId sendState:YES];
        }
        else
        {
            [mPortSIPSDK displayLocalVideo:NO];
            [mPortSIPSDK setLocalVideoWindow:nil];
            [mPortSIPSDK setRemoteVideoWindow:mSessionId remoteVideoWindow:NULL];
        }
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    isInitVideo = true;
}

- (void)viewDidAppear:(BOOL)animated;
{
    [super viewDidAppear:animated];
    [self checkDisplayVideo];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//<iOS6
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

//>=iOS6
-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if(isStartVideo)
    {
        int rotation = 0;
        switch (toInterfaceOrientation) {
            case UIInterfaceOrientationPortrait:
                rotation = 0;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                rotation = 180;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                rotation = 90;
                break;
            case UIInterfaceOrientationLandscapeRight:
                rotation = 270;
                break;
            default:
                break;
        }
        [mPortSIPSDK setVideoOrientation:rotation];
    }
}

- (BOOL) shouldAutorotate {
    
    return YES;
}

- (IBAction) onSwitchSpeakerClick: (id)sender
{
    UIButton* buttonSpeaker = (UIButton*)sender;
    
    if([[[buttonSpeaker titleLabel] text] isEqualToString:@"Speaker"])
    {
        [mPortSIPSDK setLoudspeakerStatus:YES];
        [buttonSpeaker setTitle:@"Headphone" forState: UIControlStateNormal];
    }
    else
    {
        [mPortSIPSDK setLoudspeakerStatus:NO];
        [buttonSpeaker setTitle:@"Speaker" forState: UIControlStateNormal];
    }
}

- (IBAction) onSwitchCameraClick: (id)sender
{
    UIButton* buttonCamera = (UIButton*)sender;
    
    if([[[buttonCamera titleLabel] text] isEqualToString:@"FrontCamera"])
    {
        [mPortSIPSDK setVideoDeviceId:1];
        [buttonCamera setTitle:@"BackCamera" forState: UIControlStateNormal];
    }
    else
    {
        [mPortSIPSDK setVideoDeviceId:0];
        [buttonCamera setTitle:@"FrontCamera" forState: UIControlStateNormal];
    }
    [mPortSIPSDK setLocalVideoWindow:viewLocalVideo];
    
}

- (IBAction) onSendingVideoClick: (id)sender
{
    UIButton* buttonSendingVideo = (UIButton*)sender;
    
    if([[[buttonSendingVideo titleLabel] text] isEqualToString:@"PauseSending"])
    {
        [mPortSIPSDK sendVideo:mSessionId sendState:FALSE];

        [buttonSendingVideo setTitle:@"StartSending" forState: UIControlStateNormal];
    }
    else
    {
        [mPortSIPSDK sendVideo:mSessionId sendState:TRUE];
        [buttonSendingVideo setTitle:@"PauseSending" forState: UIControlStateNormal];
    }
}

- (void)onStartVideo:(long)sessionId
{
    isStartVideo = YES;
    mSessionId = sessionId;
    [self checkDisplayVideo];

}

- (void)onStopVideo:(long)sessionId
{
    isStartVideo = NO;
    [self checkDisplayVideo];
}

@end
