//
//  JCAppIntro.m
//  JiveOne
//
//  Created by Doug on 6/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAppIntro.h"
#import "JCStyleKit.h"
#import "JCLoginViewController.h"

#define NUMBER_OF_PAGES 4
#define timeForPage(page) (NSInteger)(self.view.frame.size.width * (page - 1))
#define kTopLeft_x -110
#define kTopLeft_y -55
#define kTopRight_x 5
#define kTopRight_y -70
#define kBottomLeft_x -15
#define kBottomLeft_y 125
#define kBottomRight_x 70
#define kBottomRight_y 95
#define blueTextColor [UIColor colorWithRed:0.070 green:0.675 blue:0.999 alpha:1.000]



@interface JCAppIntro ()
@property (strong, nonatomic) UIImageView *backgroundImg;

@property (strong, nonatomic) UIImageView *voicemailCell;
@property (strong, nonatomic) UIImageView *vmPlay;
@property (strong, nonatomic) UIImageView *vmScrubber;
@property (strong, nonatomic) UIImageView *vmIcon;
@property (strong, nonatomic) UIImageView *vmTrash;
@property (strong, nonatomic) UIImageView *vmSpeaker;
@property (strong, nonatomic) UILabel *vmTimeLabel;
@property (strong, nonatomic) UILabel *vmTimeLabel2;
@property (strong, nonatomic) UILabel *callerIdLabel;
@property (strong, nonatomic) UILabel *vmDateLabel;
@property (strong, nonatomic) UILabel *vmDateTimeLabel;
@property (strong, nonatomic) UILabel *vmExtLabel;

@property (strong, nonatomic) UIImageView *bottomRight;
@property (strong, nonatomic) UIImageView *bottomLeft;
@property (strong, nonatomic) UIImageView *topRight;
@property (strong, nonatomic) UIImageView *topLeft;
@property (strong, nonatomic) UILabel *bottomRightLabel;
@property (strong, nonatomic) UILabel *bottomLeftLabel;
@property (strong, nonatomic) UILabel *topRightLabel;
@property (strong, nonatomic) UILabel *topLeftLabel;
@property (strong, nonatomic) UILabel *thridPageLabel1;
@property (strong, nonatomic) UILabel *thridPageLabel2;
@property (strong, nonatomic) UILabel *thridPageLabel3;

@property (strong, nonatomic) UIImageView *wordmark;
@property (strong, nonatomic) UILabel *lastLabel;
@property (strong, nonatomic) UILabel *firstLabel;

@end

@implementation JCAppIntro

+ (id)sharedInstance {
    static JCAppIntro *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    if ((self = [super init])) {
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.scrollView.contentSize = CGSizeMake(NUMBER_OF_PAGES * CGRectGetWidth(self.view.frame),
                                             CGRectGetHeight(self.view.frame));

    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.animator = [IFTTTAnimator new];
    [self.scrollView addSubview:self.dismissButton];
    
    [self placeViews];
    [self configureAnimation];
    [UIView animateWithDuration:1.0 animations:^{
        [self.voicemailCell setAlpha:1.0];
        [self.firstLabel setAlpha:1.0];

    } completion: ^(BOOL finished){
        if(finished) {
        }
    }];
    
}

- (void)placeViews
{
    
    //******************************************************
    //Add a static background img for view
    //******************************************************
    UIImage *bgImage = [UIImage imageNamed:@"iPhone2Xnew.png"];
    bgImage = [bgImage applyBlurWithRadius:15.0 tintColor:[[UIColor darkGrayColor] colorWithAlphaComponent:.3] saturationDeltaFactor:.88 maskImage:nil];
    self.backgroundImg = [[UIImageView alloc] initWithImage:bgImage];
    
    JCAppIntro* appIntroSingleton = [JCAppIntro sharedInstance];
    [self.backgroundImageView setImage:appIntroSingleton.backgroundImageView.image];
    
    //******************************************************
    //Add voicemailCell to center of page1
    //******************************************************
    float voicemailCell_w = 278;
    float voicemailCell_h = 157;
    self.voicemailCell = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfVoicemailCell]];
    self.voicemailCell.center = self.view.center;
    float voicemailCell_x = ((timeForPage(1))+(self.view.frame.size.width/2)-(voicemailCell_w/2));
    float voicemailCell_y = ((timeForPage(1))+(self.view.frame.size.height/2)-(voicemailCell_h/2));
    [self.voicemailCell setAlpha:0.0];
    self.voicemailCell.frame = CGRectMake(voicemailCell_x, voicemailCell_y, voicemailCell_w, voicemailCell_h);
    [self.scrollView addSubview:self.voicemailCell];

    //******************************************************
    //Add individual Imgs to the voicemailCell
    //******************************************************
    self.vmPlay = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfPlayLoginWithPlayPauseDisplaysPlay:true]];
    self.vmPlay.center = self.voicemailCell.center;
    self.vmPlay.frame = CGRectMake(0, 0, 50, 50);
    self.vmPlay.frame = CGRectOffset(self.vmPlay.frame, 5, 60);
    [self.voicemailCell addSubview:self.vmPlay];
    
    self.vmIcon = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfVoicemailIcon]];
    self.vmIcon.center = self.voicemailCell.center;
    self.vmIcon.frame = CGRectMake(0, 0, 25, 25);
    self.vmIcon.frame = CGRectOffset(self.vmIcon.frame, self.voicemailCell.frame.size.width -27, 29);
    [self.voicemailCell addSubview:self.vmIcon];
    
    self.vmScrubber = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfScrubberLogin]];
    self.vmScrubber.center = self.voicemailCell.center;
    self.vmScrubber.frame = CGRectOffset(self.vmScrubber.frame, -20, -210);
    [self.voicemailCell addSubview:self.vmScrubber];
    
    self.vmTrash = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfTrashLogin]];
    self.vmTrash.center = self.voicemailCell.center;
    self.vmTrash.frame = CGRectOffset(self.vmTrash.frame, timeForPage(1) + 30, -170);
    [self.voicemailCell addSubview:self.vmTrash];
    
    self.vmSpeaker = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfSpeakerLogin]];
    self.vmSpeaker.center = self.voicemailCell.center;
    self.vmSpeaker.frame = CGRectOffset(self.vmSpeaker.frame, timeForPage(1) - 45, -170);
    [self.voicemailCell addSubview:self.vmSpeaker];
    
    
    UILabel *callerIdLabel = [[UILabel alloc] init];
    callerIdLabel.text = @"Troy Sheilds";
    [callerIdLabel sizeToFit];
    [callerIdLabel setTextColor:[UIColor blackColor]];
    callerIdLabel.center = self.voicemailCell.center;
    [callerIdLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:14]];
    callerIdLabel.frame = CGRectOffset(self.voicemailCell.frame, timeForPage(1) + 32, -269);
    [self.voicemailCell addSubview:callerIdLabel];

    UILabel *vmDateLabel = [[UILabel alloc] init];
    vmDateLabel.text = @"May 22";
    [vmDateLabel sizeToFit];
    [vmDateLabel setTextColor:[UIColor lightGrayColor]];
    vmDateLabel.center = self.voicemailCell.center;
    [vmDateLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12]];
    vmDateLabel.frame = CGRectOffset(self.voicemailCell.frame, timeForPage(1) + self.voicemailCell.frame.size.width - 68 , -268);
    [self.voicemailCell addSubview:vmDateLabel];
    
    UILabel *vmDateTimeLabel = [[UILabel alloc] init];
    vmDateTimeLabel.text = @"2014 08:15 PM";
    [vmDateTimeLabel sizeToFit];
    [vmDateTimeLabel setTextColor:[UIColor lightGrayColor]];
    vmDateTimeLabel.center = self.voicemailCell.center;
    [vmDateTimeLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12]];
    vmDateTimeLabel.frame = CGRectOffset(self.voicemailCell.frame, timeForPage(1) + 64, -227);
    [self.voicemailCell addSubview:vmDateTimeLabel];
    
    
    UILabel *vmTimeLabel2 = [[UILabel alloc] init];
    vmTimeLabel2.text = @"0:05";
    [vmTimeLabel2 sizeToFit];
    [vmTimeLabel2 setTextColor:[UIColor blackColor]];
    vmTimeLabel2.center = self.voicemailCell.center;
    [vmTimeLabel2 setFont:[UIFont fontWithName:@"AppleSDGothicNeo-Bold" size:8]];
    vmTimeLabel2.frame = CGRectOffset(self.voicemailCell.frame, timeForPage(1) + self.voicemailCell.frame.size.width - 44, -199);
    [self.voicemailCell addSubview:vmTimeLabel2];
    
    
    UILabel *vmExtLabel = [[UILabel alloc] init];
    vmExtLabel.text = @"7718";
    [vmExtLabel sizeToFit];
    [vmExtLabel setTextColor:[UIColor blackColor]];
    vmExtLabel.center = self.voicemailCell.center;
    [vmExtLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12]];
    vmExtLabel.frame = CGRectOffset(self.voicemailCell.frame, timeForPage(1) + 39, -249);
    [self.voicemailCell addSubview:vmExtLabel];
   
    
    //TODO: Remove this
    self.wordmark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"main-logo.png"]];
    self.wordmark.center = self.view.center;
    self.wordmark.frame = CGRectOffset(self.wordmark.frame, self.view.frame.size.width, -10);
    //[self.scrollView addSubview:self.wordmark];
    
    //******************************************************
    //add topLeft to page2
    //******************************************************
    self.topLeft = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfTopLeft]];
    self.topLeft.center = self.view.center;
    self.topLeft.frame = CGRectOffset(self.topLeft.frame, kTopLeft_x, kTopLeft_y);
    [self.topLeft setAlpha:0.0];
    [self.scrollView addSubview:self.topLeft];
    NSLog(@"----%@",NSStringFromCGRect(self.topLeft.frame));
    
    //******************************************************
    //add topRight to page2
    //******************************************************
    self.topRight = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfTopRight]];
    self.topRight.center = self.view.center;
    self.topRight.frame = CGRectOffset( self.topRight.frame, kTopRight_x, kTopRight_y );
    [self.topRight setAlpha:0.0];
    [self.scrollView addSubview:self.topRight];
    
    //******************************************************
    //add bottomLeft to page2
    //******************************************************
    self.bottomLeft = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfBottomLeft]];
    self.bottomLeft.center = self.view.center;
    self.bottomLeft.frame = CGRectOffset( self.bottomLeft.frame, kBottomLeft_x, kBottomLeft_y );
    [self.bottomLeft setAlpha:0.0];
    [self.scrollView addSubview:self.bottomLeft];
    
    //******************************************************
    //add bottomRight to page2
    //******************************************************
    self.bottomRight = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfBottomRight]];
    self.bottomRight.center = self.view.center;
    self.bottomRight.frame = CGRectOffset(self.bottomRight.frame, kBottomRight_x, kBottomRight_y);
    [self.bottomRight setAlpha:0.0];
    [self.scrollView addSubview:self.bottomRight];
    
#define kTopLeft_x_Offset -80
#define kTopRight_x_Offset 50
#define kBottomLeft_x_Offset 130
#define kBottomRight_x_Offset 75

    //******************************************************
    //This is where we add all the text the the labels of the tutorials
    //******************************************************
    UILabel *firstPageText = [[UILabel alloc] init];
    firstPageText.text = @"Introducing The Jive Voicemail App";
    firstPageText.textColor = [UIColor whiteColor];
    [firstPageText sizeToFit];
    firstPageText.center = self.view.center;
    [firstPageText setAlpha:0.0];
    firstPageText.frame = CGRectOffset(firstPageText.frame, timeForPage(1), -180);
    self.firstLabel = firstPageText;
    [self.scrollView addSubview:firstPageText];
    
    UILabel *playPauseText = [[UILabel alloc] init];
    playPauseText.text = @"Play/Pause";
    [playPauseText sizeToFit];
    [playPauseText setTextColor:blueTextColor];
    playPauseText.center = self.view.center;
    [playPauseText setFont:[UIFont fontWithName:@"MarkerFelt-Wide" size:16]];
    playPauseText.frame = CGRectOffset(playPauseText.frame, timeForPage(2) + kTopLeft_x_Offset, -110);
    [self.scrollView addSubview:playPauseText];
    self.topLeftLabel = playPauseText;
    
    UILabel *scrubberText = [[UILabel alloc] init];
    scrubberText.text = @"Span voicemail segments";
    [scrubberText sizeToFit];
    [scrubberText setTextColor:blueTextColor];
    scrubberText.center = self.view.center;
    [scrubberText setFont:[UIFont fontWithName:@"MarkerFelt-Wide" size:16]];
    scrubberText.frame = CGRectOffset(scrubberText.frame, timeForPage(2) + kTopRight_x_Offset, -160);
    [self.scrollView addSubview:scrubberText];
    self.topRightLabel = scrubberText;
    
    UILabel *speakerText = [[UILabel alloc] init];
    speakerText.text = @"Listen to your message using Jive's patented Sonar Technology.";
    [speakerText sizeToFit];
    [speakerText setTextColor:blueTextColor];
    speakerText.center = self.view.center;
    [speakerText setFont:[UIFont fontWithName:@"MarkerFelt-Wide" size:16]];
    speakerText.frame = CGRectMake(speakerText.frame.origin.x, speakerText.frame.origin.y, 200, 50);
    [speakerText setNumberOfLines:0];
    [speakerText setLineBreakMode:NSLineBreakByWordWrapping];
    speakerText.frame = CGRectOffset(speakerText.frame, timeForPage(2) + kBottomLeft_x_Offset, 190);
    [self.scrollView addSubview:speakerText];
    self.bottomLeftLabel = speakerText;
    
    UILabel *deleteText = [[UILabel alloc] init];
    deleteText.text = @"Expunge";
    [deleteText sizeToFit];
    [deleteText setTextColor:blueTextColor];
    deleteText.center = self.view.center;
    [deleteText setFont:[UIFont fontWithName:@"MarkerFelt-Wide" size:16]];
    deleteText.frame = CGRectOffset(deleteText.frame, timeForPage(2) + kBottomRight_x_Offset, 140);
    [self.scrollView addSubview:deleteText];
    self.bottomRightLabel = deleteText;
    
    UILabel *leaveFeedbackLabel = [[UILabel alloc] init];
    leaveFeedbackLabel.text = @"Send us feedback!";
    leaveFeedbackLabel.textColor = [UIColor whiteColor];
    [leaveFeedbackLabel sizeToFit];
    leaveFeedbackLabel.center = self.view.center;
    leaveFeedbackLabel.frame = CGRectOffset(leaveFeedbackLabel.frame, timeForPage(3), -100);
    [self.scrollView addSubview:leaveFeedbackLabel];
    self.thridPageLabel1 = leaveFeedbackLabel;
    
    UILabel *leaveFeedbackLabel2 = [[UILabel alloc] init];
    leaveFeedbackLabel2.text = @"We want to hear from you!";
    leaveFeedbackLabel2.textColor = [UIColor whiteColor];
    [leaveFeedbackLabel2 sizeToFit];
    leaveFeedbackLabel2.center = self.view.center;
    leaveFeedbackLabel2.frame = CGRectOffset(leaveFeedbackLabel2.frame, timeForPage(3), -50);
    [self.scrollView addSubview:leaveFeedbackLabel2];
    self.thridPageLabel1 = leaveFeedbackLabel2;
    
    UILabel *emailLabel = [[UILabel alloc] init];
    emailLabel.text = @"MobileApps+ios@jive.com";
    emailLabel.textColor = [UIColor whiteColor];
    [emailLabel sizeToFit];
    emailLabel.center = self.view.center;
    emailLabel.frame = CGRectOffset(emailLabel.frame, timeForPage(3), 0);
    [self.scrollView addSubview:emailLabel];
    self.thridPageLabel1 = emailLabel;
    
    UILabel *fourthPageText = [[UILabel alloc] init];
    fourthPageText.text = @"Dismiss";
    fourthPageText.textColor = [UIColor whiteColor];
    [fourthPageText sizeToFit];
    fourthPageText.center = self.view.center;
    fourthPageText.frame = CGRectOffset(fourthPageText.frame, timeForPage(4), 0);
    [self.scrollView addSubview:fourthPageText];

    self.lastLabel = fourthPageText;
    
    self.dismissButton.frame = CGRectOffset(self.dismissButton.frame, timeForPage(1), 0);
}

- (void)configureAnimation
{
    CGFloat dy = 240;
    CGFloat upDy = -300;
    
    // apply a 3D zoom animation to the first label
//    IFTTTTransform3DAnimation * labelTransform = [IFTTTTransform3DAnimation animationWithView:self.firstLabel];
//    IFTTTTransform3D *tt1 = [IFTTTTransform3D transformWithM34:0.03f];
//    IFTTTTransform3D *tt2 = [IFTTTTransform3D transformWithM34:0.3f];
//    tt2.rotate = (IFTTTTransform3DRotate){ -(CGFloat)(M_PI), 1, 0, 0 };
//    tt2.translate = (IFTTTTransform3DTranslate){ 0, 0, 50 };
//    tt2.scale = (IFTTTTransform3DScale){ 1.f, 2.f, 1.f };
//    [labelTransform addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(0)
//                                                                andAlpha:1.0f]];
//    [labelTransform addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1)
//                                                          andTransform3D:tt1]];
//    [labelTransform addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1.5)
//                                                          andTransform3D:tt2]];
//    [labelTransform addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1.5) + 1
//                                                                andAlpha:0.0f]];
//    [self.animator addAnimation:labelTransform];
    //******************************************************
    // let's animate the wordmark
    //******************************************************
    IFTTTFrameAnimation *wordmarkFrameAnimation = [IFTTTFrameAnimation animationWithView:self.wordmark];
    [self.animator addAnimation:wordmarkFrameAnimation];
    
    [wordmarkFrameAnimation addKeyFrames:@[
                                           [IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:CGRectOffset(self.wordmark.frame, 200, 0)],
                                           [IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:self.wordmark.frame],
                                           [IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(self.wordmark.frame, self.view.frame.size.width, dy)],
                                           [IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andFrame:CGRectOffset(self.wordmark.frame, 0, dy)],
                                           ]];
    // Rotate a full circle from page 2 to 3
    IFTTTAngleAnimation *wordmarkRotationAnimation = [IFTTTAngleAnimation animationWithView:self.wordmark];
    [self.animator addAnimation:wordmarkRotationAnimation];
    [wordmarkRotationAnimation addKeyFrames:@[[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAngle:0.0f],
                                              [IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAngle:(CGFloat)(2 * M_PI)],]];
    
    //******************************************************
    // now, we animate the voicemailCell
    //******************************************************
    IFTTTFrameAnimation *voicemailCellFrameAnimation = [IFTTTFrameAnimation animationWithView:self.voicemailCell];
    [self.animator addAnimation:voicemailCellFrameAnimation];
    
    // the higher this number is the more the objects shrink
    CGFloat ds = 0;
    
    // move down and to the right, and shrink between pages 2 and 3
    [voicemailCellFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:self.voicemailCell.frame]];
    [voicemailCellFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:CGRectOffset(self.voicemailCell.frame, timeForPage(2), 0)]];
    
    
    //******************************************************
    // now, we animate the topLeft
    //******************************************************
    IFTTTFrameAnimation *topLeftFrameAnimation = [IFTTTFrameAnimation animationWithView:self.topLeft];
    [self.animator addAnimation:topLeftFrameAnimation];
    
    // move down and to the right, and shrink between pages 2 and 3
    CGRect topLeftStartFrame = CGRectOffset(self.topLeft.frame, -(self.topLeft.frame.origin.x + self.topLeft.frame.size.width), 0);
    [topLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:topLeftStartFrame]];
    [topLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:CGRectOffset(self.topLeft.frame, timeForPage(2), 0)]];
    [topLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(self.topLeft.frame, timeForPage(3), upDy)]];
    
    //******************************************************
    // now, we animate the topRight
    //******************************************************
    IFTTTFrameAnimation *topRightFrameAnimation = [IFTTTFrameAnimation animationWithView:self.topRight];
    [self.animator addAnimation:topRightFrameAnimation];
    CGRect topRightStartFrame = CGRectOffset(self.topRight.frame, (self.view.frame.size.width - self.topRight.frame.size.width), 0);
    CGRect topRightFrame2 = CGRectOffset(self.topRight.frame, (self.view.frame.size.width + kTopRight_x), 0);
    [topRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:topRightStartFrame]];
    [topRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:topRightFrame2]];
    [topRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(CGRectInset(self.topRight.frame, ds, ds), timeForPage(3), upDy)]];

    //******************************************************
    // now, we animate the bottomLeft
    //******************************************************
    IFTTTFrameAnimation *bottomLeftFrameAnimation = [IFTTTFrameAnimation animationWithView:self.bottomLeft];
    [self.animator addAnimation:bottomLeftFrameAnimation];
    
    // move down and to the right, and shrink between pages 2 and 3
    CGRect bottomLeftStartFrame = CGRectOffset(self.bottomLeft.frame, -(self.bottomLeft.frame.origin.x + self.bottomLeft.frame.size.width), 0);
    [bottomLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:bottomLeftStartFrame]];
    [bottomLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:CGRectOffset(self.bottomLeft.frame, timeForPage(2), 0)]];
    [bottomLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(CGRectInset(self.bottomLeft.frame, ds, ds), timeForPage(3), dy)]];
    IFTTTFrameAnimation *bottomRightFrameAnimation = [IFTTTFrameAnimation animationWithView:self.bottomRight];
    [self.animator addAnimation:bottomRightFrameAnimation];
    
    // anamate on to the screen then animate off page 3
    CGRect bottomRightStartFrame = CGRectOffset(self.bottomRight.frame, (self.view.frame.size.width - self.bottomRight.frame.size.width), 0);
    [bottomRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:bottomRightStartFrame]];
    [bottomRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:CGRectOffset(self.bottomRight.frame, timeForPage(2), 0)]];
    [bottomRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(CGRectInset(self.bottomRight.frame, ds, ds), timeForPage(3), dy)]];
    
    //******************************************************
    //fade all the Arrows in on page 2 and out on page 4
    //******************************************************
        IFTTTAlphaAnimation *topLeftAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.topLeft];
        [self.animator addAnimation:topLeftAlphaAnimation];
    
    [topLeftAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andAlpha:0.0f]];
    [topLeftAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:1.0f]];
    [topLeftAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:1.0f]];
    [topLeftAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:0.0f]];
    
    IFTTTAlphaAnimation *topRightAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.topRight];
    [self.animator addAnimation:topRightAlphaAnimation];
    
    [topRightAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andAlpha:0.0f]];
    [topRightAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:1.0f]];
    [topRightAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:1.0f]];
    [topRightAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:0.0f]];
    
    IFTTTAlphaAnimation *bottomLeftAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.bottomLeft];
    [self.animator addAnimation:bottomLeftAlphaAnimation];
    
    [bottomLeftAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andAlpha:0.0f]];
    [bottomLeftAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:1.0f]];
    [bottomLeftAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:1.0f]];
    [bottomLeftAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:0.0f]];
    
    IFTTTAlphaAnimation *bottomRightAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.bottomRight];
    [self.animator addAnimation:bottomRightAlphaAnimation];
    
    [bottomRightAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andAlpha:0.0f]];
    [bottomRightAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:1.0f]];
    [bottomRightAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:1.0f]];
    [bottomRightAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:0.0f]];
    
    //******************************************************
    // Fade out the label by dragging on the last page
    //******************************************************
    IFTTTAlphaAnimation *labelAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.lastLabel];
    [labelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:1.0f]];
    [labelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4.35f) andAlpha:0.0f]];
    [self.animator addAnimation:labelAlphaAnimation];
}

#pragma mark - IFTTTAnimatedScrollViewControllerDelegate

- (void)animatedScrollViewControllerDidScrollToEnd:(IFTTTAnimatedScrollViewController *)animatedScrollViewController
{
    NSLog(@"Scrolled to end of scrollview!");
    NSLog(@"%f,%f",self.dismissButton.frame.origin.x,self.dismissButton.frame.origin.y);
}

- (void)animatedScrollViewControllerDidEndDraggingAtEnd:(IFTTTAnimatedScrollViewController *)animatedScrollViewController
{
    NSLog(@"Ended dragging at end of scrollview!");
}

- (IBAction)dismissButtonWasPressed:(id)sender {
    [self dismissViewControllerAnimated:NO completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AppTutorialDismissed" object:nil];
    }];
    //Register for PushNotifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                           UIRemoteNotificationTypeBadge |
                                                                           UIRemoteNotificationTypeSound)];
}


@end
