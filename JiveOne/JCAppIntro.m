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

//Arrows
#define kTopLeft_x -110
#define kTopLeft_y -55
#define kTopRight_x 5
#define kTopRight_y -70
#define kBottomLeft_x -15
#define kBottomLeft_y 115
#define kBottomRight_x 65
#define kBottomRight_y 95
#define labelTextColor [UIColor whiteColor]

//Labels
#define kTopLeft_x_Offset -80
#define kTopLeft_y_Offset -110

#define kTopRight_x_Offset 45
#define kTopRight_y_Offset -160

#define kBottomLeft_x_Offset -75
#define kBottomLeft_y_Offset 190

#define kBottomRight_x_Offset 75
#define kBottomRight_y_Offset 150

#define kFontSize 24
//Buttons
#define kgetStartedButton_x timeForPage(3)
#define kgetStartedButton_y 200

//Fonts
#define kIntroFont @"Alpine Script"

#define kDy 240
#define kUpDy -300
#define kDs  0

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
@property (strong, nonatomic) UILabel *comingSoon;

@property (strong, nonatomic) UIImageView *bottomRight;
@property (strong, nonatomic) UIImageView *bottomLeft;
@property (strong, nonatomic) UIImageView *topRight;
@property (strong, nonatomic) UIImageView *topLeft;
@property (strong, nonatomic) JCJiveLogoWhite *jiveLogoWhite;
@property (strong, nonatomic) JCVoicemailIcon *voicemailIconWhite;

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
    self.delegate = self;
    [self setupBackground];
    [self setupPage1];
    [self setupPage2];
    [self setupPage3];
    [self setupPage4];
    [UIView animateWithDuration:1.0 animations:^{
        [self.voicemailCell setAlpha:1.0];
        [self.firstLabel setAlpha:1.0];
        [self.jiveLogoWhite setAlpha:1.0];
        [self.voicemailCell setAlpha:1.0];
    } completion: ^(BOOL finished){
        if(finished) {
        }
    }];
    
}

#pragma mark - setup
- (void)setupBackground
{
    
    //******************************************************
    //Add a static background img for view
    //******************************************************
    UIImage *bgImage = [UIImage imageNamed:@"iPhone2Xnew.png"];
    bgImage = [bgImage applyBlurWithRadius:15.0 tintColor:[[UIColor darkGrayColor] colorWithAlphaComponent:.3] saturationDeltaFactor:.88 maskImage:nil];
    self.backgroundImg = [[UIImageView alloc] initWithImage:bgImage];
    
    JCAppIntro* appIntroSingleton = [JCAppIntro sharedInstance];
    [self.backgroundImageView setImage:appIntroSingleton.backgroundImageView.image];
}

//This is the main utility function that puts an img in a certain place on the page along with how wide and high it is
-(UIImageView*)createImageViewUsingDictionary:(NSDictionary*)argumentDict {
    
    UIImageView* imageView = [argumentDict valueForKey:@"imageView"];
    imageView = imageView;
    int x =(int)[argumentDict valueForKey:@"x"];
    int y =(int)[argumentDict valueForKey:@"y"];
    int w =(int)[argumentDict valueForKey:@"w"];
    int h =(int)[argumentDict valueForKey:@"h"];
    int a =(int)[argumentDict valueForKey:@"a"];
    
    [imageView setAlpha:((CGFloat)a)];
    [imageView setFrame:CGRectMake(x, y, w, h)];
    
    return imageView;
}

#pragma mark - page1
- (void)setupPage1
{
    //******************************************************
    //Add voicemailCell to center of page1
    //******************************************************
    
    self.voicemailCell = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfVoicemailCell]];
    //self.voicemailCell.center = self.view.center;
    NSDictionary *d = @{@"x": @1,//((timeForPage(1))+(self.view.frame.size.width/2)-(self.voicemailCell.frame.size.width/2)),
                        @"y": @12,//((timeForPage(1))+(self.view.frame.size.height/2)-(self.voicemailCell.frame.size.height/2)),
                        @"w": @18,
                        @"h": @11,
                        @"a": @0,
                        @"imageView": self.voicemailCell};
    self.voicemailCell = [self createImageViewUsingDictionary:d];
    
//    float voicemailCell_w = 278;
//    float voicemailCell_h = 157;
//    self.voicemailCell = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfVoicemailCell]];
//    self.voicemailCell.center = self.view.center;
//    float voicemailCell_x = ((timeForPage(1))+(self.view.frame.size.width/2)-(voicemailCell_w/2));
//    float voicemailCell_y = ((timeForPage(1))+(self.view.frame.size.height/2)-(voicemailCell_h/2));
//    [self.voicemailCell setAlpha:0.0];
//    self.voicemailCell.frame = CGRectMake(voicemailCell_x, voicemailCell_y, voicemailCell_w, voicemailCell_h);
    
    
    CALayer *shadowLayervoicemailCell = self.voicemailCell.layer;
    shadowLayervoicemailCell.shadowOffset = CGSizeZero;
    shadowLayervoicemailCell.shadowColor = [[UIColor blackColor] CGColor];
    shadowLayervoicemailCell.shadowRadius = 3.0f;
    shadowLayervoicemailCell.shadowOpacity = 0.50f;
    shadowLayervoicemailCell.shadowPath = [self awesomeShadow:shadowLayervoicemailCell.bounds];
    [self.scrollView addSubview:self.voicemailCell];
    
    //******************************************************
    //Add individual Images to the voicemailCell
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
    
    //******************************************************
    //Add JiveLogoWhite to page 1
    //******************************************************
    float jiveLogoWhite_w = 150;
    float jiveLogoWhite_h = 150;
    CGRect jiveLogoFrame = CGRectMake(300, 300, jiveLogoWhite_w, jiveLogoWhite_h);
    self.jiveLogoWhite = [[JCJiveLogoWhite alloc]initWithFrame:jiveLogoFrame];
    self.jiveLogoWhite.backgroundColor = [UIColor clearColor];
    self.jiveLogoWhite.center = self.view.center;
    //    UIImageView *jiveLogoWhite = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfJiveLogoWhiteWithFrame:(jiveLogoFrame)]];
    float jiveLogoWhite_x = ((timeForPage(1))+(self.view.frame.size.width/2)-(jiveLogoWhite_w/2));
    float jiveLogoWhite_y = 20;
    [self.jiveLogoWhite setAlpha:0.0];
    self.jiveLogoWhite.frame = CGRectMake(jiveLogoWhite_x, jiveLogoWhite_y, jiveLogoWhite_w, jiveLogoWhite_h);
    [self.scrollView addSubview:self.jiveLogoWhite];
    
    
    
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
    
    //******************************************************
    //This is where we add all the text the the labels of the tutorials
    //******************************************************
    UILabel *firstPageText = [[UILabel alloc] init];
    firstPageText.text = @"The Jive Voicemail App lets you consume and manage all of your voicemail messages.";
    [firstPageText setFont:[UIFont fontWithName:kIntroFont size:kFontSize]];
    [firstPageText setTextColor:labelTextColor];
    firstPageText.shadowColor = [UIColor darkGrayColor];
    firstPageText.shadowOffset = CGSizeMake(0, 1);
    [firstPageText setNumberOfLines:0];
    [firstPageText setLineBreakMode:NSLineBreakByWordWrapping];
    firstPageText.frame = CGRectMake(firstPageText.frame.origin.x, firstPageText.frame.origin.y, 250, 100);
    //    [firstPageText sizeToFit];
    
    firstPageText.center = self.view.center;
    [firstPageText setAlpha:0.0];
    firstPageText.frame = CGRectOffset(firstPageText.frame, timeForPage(1), 140);
    self.firstLabel = firstPageText;
    [self.scrollView addSubview:firstPageText];
    
    UILabel *playPauseText = [[UILabel alloc] init];
    playPauseText.text = @"Play/Pause";
    [playPauseText setFont:[UIFont fontWithName:kIntroFont size:kFontSize]];
    [playPauseText sizeToFit];
    [playPauseText setTextColor:labelTextColor];
    playPauseText.shadowColor = [UIColor darkGrayColor];
    playPauseText.shadowOffset = CGSizeMake(0, 1);
    playPauseText.center = self.view.center;
    playPauseText.frame = CGRectOffset(playPauseText.frame, timeForPage(1) + kTopLeft_x_Offset, kTopLeft_y_Offset);
    [playPauseText setAlpha:0.0];
    self.topLeftLabel = playPauseText;
    [self.scrollView addSubview:self.topLeftLabel];
    
    CGRect ppFrame = CGRectMake(100, 100, 125, 39);
    UIImageView *playPauseImageView = [[UIImageView alloc]initWithImage:[JCStyleKit imageOfPlayPauseTextWithFrame:ppFrame]];
    [self.scrollView addSubview:playPauseImageView];
    
    UILabel *scrubberText = [[UILabel alloc] init];
    scrubberText.text = @"Span voicemail segments";
    [scrubberText setFont:[UIFont fontWithName:kIntroFont size:kFontSize]];
    [scrubberText sizeToFit];
    [scrubberText setTextColor:labelTextColor];
    scrubberText.shadowColor = [UIColor darkGrayColor];
    scrubberText.shadowOffset = CGSizeMake(0, 1);
    scrubberText.center = self.view.center;
    scrubberText.frame = CGRectOffset(scrubberText.frame, timeForPage(1) + kTopRight_x_Offset, kTopRight_y_Offset);
    [scrubberText setAlpha:0.0];
    [self.scrollView addSubview:scrubberText];
    self.topRightLabel = scrubberText;
    NSLog(@"ScrT%@",NSStringFromCGRect(scrubberText.frame));
    
    
    UILabel *speakerText = [[UILabel alloc] init];
    speakerText.text = @"Speaker On/Off";
    [speakerText setFont:[UIFont fontWithName:kIntroFont size:kFontSize]];
    [speakerText sizeToFit];
    [speakerText setTextColor:labelTextColor];
    speakerText.shadowColor = [UIColor darkGrayColor];
    speakerText.shadowOffset = CGSizeMake(0, 1);
    speakerText.center = self.view.center;
    speakerText.frame = CGRectOffset(speakerText.frame, timeForPage(1) + kBottomLeft_x_Offset, kBottomLeft_y_Offset);
    [speakerText setAlpha:0.0];
    [self.scrollView addSubview:speakerText];
    self.bottomLeftLabel = speakerText;
    
    UILabel *deleteText = [[UILabel alloc] init];
    deleteText.text = @"Delete";
    [deleteText setFont:[UIFont fontWithName:kIntroFont size:kFontSize]];
    [deleteText sizeToFit];
    [deleteText setTextColor:labelTextColor];
    deleteText.shadowColor = [UIColor darkGrayColor];
    deleteText.shadowOffset = CGSizeMake(0, 1);
    deleteText.center = self.view.center;
    deleteText.frame = CGRectOffset(deleteText.frame, timeForPage(1) + kBottomRight_x_Offset, kBottomRight_y_Offset);
    [deleteText setAlpha:0.0];
    [self.scrollView addSubview:deleteText];
    self.bottomRightLabel = deleteText;
    
    //******************************************************
    // now, we animate the voicemailCell
    //******************************************************
    IFTTTFrameAnimation *voicemailCellFrameAnimation = [IFTTTFrameAnimation animationWithView:self.voicemailCell];
    [self.animator addAnimation:voicemailCellFrameAnimation];
    
    // the higher this number is the more the objects shrink
    
    
    // pages 2 and 3
    [voicemailCellFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:self.voicemailCell.frame]];
    [voicemailCellFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:CGRectOffset(self.voicemailCell.frame, timeForPage(2), 0)]];
    
    
    //******************************************************
    // now, we animate the JiveLogoWhite
    //******************************************************
    IFTTTFrameAnimation *jiveLogoWhiteFrameAnimation = [IFTTTFrameAnimation animationWithView:self.jiveLogoWhite];
    [self.animator addAnimation:jiveLogoWhiteFrameAnimation];
    
    [jiveLogoWhiteFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:CGRectOffset(self.jiveLogoWhite.frame, timeForPage(1), 0)]];
    [jiveLogoWhiteFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:CGRectOffset(self.jiveLogoWhite.frame, timeForPage(2), kUpDy)]];
    
    
    //******************************************************
    // now, we animate the firstLabel
    //******************************************************
    IFTTTFrameAnimation *firstLabelFrameAnimation = [IFTTTFrameAnimation animationWithView:self.firstLabel];
    [self.animator addAnimation:firstLabelFrameAnimation];
    
    [firstLabelFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:CGRectOffset(self.firstLabel.frame, timeForPage(1), 0)]];
    [firstLabelFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:CGRectOffset(self.firstLabel.frame, timeForPage(2), kDy)]];
    
    
    //*************************************************************
    //fade JiveLogo & Voicemail Icon in on page 1 and out on page 2
    //*************************************************************
    IFTTTAlphaAnimation *jiveLogoWhiteAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.voicemailIconWhite];
    [self.animator addAnimation:jiveLogoWhiteAlphaAnimation];
    
    [jiveLogoWhiteAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andAlpha:1.0f]];
    [jiveLogoWhiteAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:1.0f]];
    [jiveLogoWhiteAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:0.0f]];
    [jiveLogoWhiteAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:0.0f]];
    
    IFTTTAlphaAnimation *voicemailIconWhiteAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.voicemailIconWhite];
    [self.animator addAnimation:voicemailIconWhiteAlphaAnimation];
    
    [voicemailIconWhiteAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andAlpha:1.0f]];
    [voicemailIconWhiteAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:1.0f]];
    [voicemailIconWhiteAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:0.0f]];
    [voicemailIconWhiteAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:0.0f]];
}

#pragma mark - page2

- (void)setupPage2
{
    //******************************************************
    //add topLeft to page2
    //******************************************************
    self.topLeft = [[UIImageView alloc] initWithImage:[JCStyleKit imageOfTopLeft]];
    self.topLeft.center = self.view.center;
    self.topLeft.frame = CGRectOffset(self.topLeft.frame, kTopLeft_x, kTopLeft_y);
    [self.topLeft setAlpha:0.0];
    [self.scrollView addSubview:self.topLeft];
    
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
    
    //    UILabel *leaveFeedbackLabel = [[UILabel alloc] init];
    //    leaveFeedbackLabel.text = @"Send us feedback!";
    //    [leaveFeedbackLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:kFontSize]];
    //    leaveFeedbackLabel.shadowColor = [UIColor darkGrayColor];
    //    leaveFeedbackLabel.textColor = [UIColor whiteColor];
    //    leaveFeedbackLabel.shadowOffset = CGSizeMake(0, 1);
    //    [leaveFeedbackLabel sizeToFit];
    //    leaveFeedbackLabel.center = self.view.center;
    //    leaveFeedbackLabel.frame = CGRectOffset(leaveFeedbackLabel.frame, timeForPage(3), -50);
    //    [self.scrollView addSubview:leaveFeedbackLabel];
    //    self.thridPageLabel1 = leaveFeedbackLabel;
    
    UILabel *leaveFeedbackLabel2 = [[UILabel alloc] init];
    leaveFeedbackLabel2.text = @"Send us feedback!";
    [leaveFeedbackLabel2 setFont:[UIFont fontWithName:kIntroFont size:kFontSize]];
    leaveFeedbackLabel2.textColor = [UIColor whiteColor];
    leaveFeedbackLabel2.shadowColor = [UIColor darkGrayColor];
    leaveFeedbackLabel2.shadowOffset = CGSizeMake(0, 1);
    [leaveFeedbackLabel2 sizeToFit];
    leaveFeedbackLabel2.center = self.view.center;
    leaveFeedbackLabel2.frame = CGRectOffset(leaveFeedbackLabel2.frame, timeForPage(3), -55);
    [self.scrollView addSubview:leaveFeedbackLabel2];
    self.thridPageLabel1 = leaveFeedbackLabel2;
    
    UILabel *emailLabel = [[UILabel alloc] init];
    emailLabel.text = @"MobileApps+ios@jive.com";
    [emailLabel setFont:[UIFont fontWithName:kIntroFont size:kFontSize]];
    emailLabel.textColor = [UIColor whiteColor];
    emailLabel.shadowColor = [UIColor darkGrayColor];
    emailLabel.shadowOffset = CGSizeMake(0, 1);
    [emailLabel sizeToFit];
    emailLabel.center = self.view.center;
    emailLabel.frame = CGRectOffset(emailLabel.frame, timeForPage(3), -30);
    [self.scrollView addSubview:emailLabel];
    self.thridPageLabel1 = emailLabel; 
    
    //******************************************************
    // now, we animate the topLeft
    //******************************************************
    
    IFTTTFrameAnimation *topLeftFrameAnimation = [IFTTTFrameAnimation animationWithView:self.topLeft];
    [self.animator addAnimation:topLeftFrameAnimation];
    
    // move down and to the right, and shrink between pages 2 and 3
    CGRect topLeftStartFrame = CGRectOffset(self.topLeft.frame, -(self.topLeft.frame.origin.x + self.topLeft.frame.size.width), 0);
    [topLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:topLeftStartFrame]];
    [topLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:CGRectOffset(self.topLeft.frame, timeForPage(2), 0)]];
    [topLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(self.topLeft.frame, timeForPage(3), kUpDy)]];
    
    
    //******************************************************
    // now, we animate the topLeftFrame
    //******************************************************
    IFTTTFrameAnimation *topLeftLabelAnimation = [IFTTTFrameAnimation animationWithView:self.topLeftLabel];
    [self.animator addAnimation:topLeftLabelAnimation];
    
    CGRect topLeftLabelStartFrame = CGRectOffset(self.topLeftLabel.frame, -(self.topLeftLabel.frame.origin.x + self.topLeftLabel.frame.size.width), 0);
    [topLeftLabelAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:topLeftLabelStartFrame]];
    [topLeftLabelAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:CGRectOffset(self.topLeftLabel.frame, timeForPage(2), 0)]];
    [topLeftLabelAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(self.topLeftLabel.frame, timeForPage(3), kUpDy)]];
    
    
    //******************************************************
    // now, we animate the topRight
    //******************************************************
    IFTTTFrameAnimation *topRightFrameAnimation = [IFTTTFrameAnimation animationWithView:self.topRight];
    [self.animator addAnimation:topRightFrameAnimation];
    CGRect topRightStartFrame = CGRectOffset(self.topRight.frame, (self.view.frame.size.width - self.topRight.frame.size.width), 0);
    CGRect topRightFrame2 = CGRectOffset(self.topRight.frame, (self.view.frame.size.width + kTopRight_x), 0);
    [topRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:topRightStartFrame]];
    [topRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:topRightFrame2]];
    [topRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(CGRectInset(self.topRight.frame,kDs,kDs), timeForPage(3), kUpDy)]];
    
    //******************************************************
    // now, we animate the topRightLabel
    //******************************************************
    IFTTTFrameAnimation *topRightLabelAnimation = [IFTTTFrameAnimation animationWithView:self.topRightLabel];
    [self.animator addAnimation:topRightLabelAnimation];
    CGRect topRightLabelStartFrame = CGRectOffset(self.topRightLabel.frame, (self.view.frame.size.width - self.topRightLabel.frame.origin.x), 0);
    CGRect topRightLabelFrame2 = CGRectOffset(self.topRightLabel.frame, (self.view.frame.size.width + kTopRight_x), 0);
    [topRightLabelAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:topRightLabelStartFrame]];
    [topRightLabelAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:topRightLabelFrame2]];
    [topRightLabelAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(CGRectInset(self.topRightLabel.frame,kDs,kDs), timeForPage(3), kUpDy)]];
    
    //******************************************************
    // now, we animate the bottomLeft
    //******************************************************
    IFTTTFrameAnimation *bottomLeftFrameAnimation = [IFTTTFrameAnimation animationWithView:self.bottomLeft];
    [self.animator addAnimation:bottomLeftFrameAnimation];
    
    // move down and to the right, and shrink between pages 2 and 3
    CGRect bottomLeftStartFrame = CGRectOffset(self.bottomLeft.frame, -(self.bottomLeft.frame.origin.x + self.bottomLeft.frame.size.width), 0);
    [bottomLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:bottomLeftStartFrame]];
    [bottomLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:CGRectOffset(self.bottomLeft.frame, timeForPage(2), 0)]];
    [bottomLeftFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(CGRectInset(self.bottomLeft.frame,kDs,kDs), timeForPage(3), kDy)]];
    
    //******************************************************
    // now, we animate the bottomLeft
    //******************************************************
    IFTTTFrameAnimation *bottomLeftLabelAnimation = [IFTTTFrameAnimation animationWithView:self.bottomLeftLabel];
    [self.animator addAnimation:bottomLeftLabelAnimation];
    
    // move down and to the right, and shrink between pages 2 and 3
    CGRect bottomLeftLabelStartFrame = CGRectOffset(self.bottomLeftLabel.frame, -(self.bottomLeftLabel.frame.origin.x + self.bottomLeftLabel.frame.size.width), 0);
    [bottomLeftLabelAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:bottomLeftLabelStartFrame]];
    [bottomLeftLabelAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:CGRectOffset(self.bottomLeftLabel.frame, timeForPage(2), 0)]];
    [bottomLeftLabelAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(CGRectInset(self.bottomLeftLabel.frame,kDs,kDs), timeForPage(3), kDy)]];
    
    //******************************************************
    // now, we animate the bottomRight
    //******************************************************
    IFTTTFrameAnimation *bottomRightFrameAnimation = [IFTTTFrameAnimation animationWithView:self.bottomRight];
    [self.animator addAnimation:bottomRightFrameAnimation];
    
    CGRect bottomRightStartFrame = CGRectOffset(self.bottomRight.frame, (self.view.frame.size.width - self.bottomRight.frame.size.width), 0);
    [bottomRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:bottomRightStartFrame]];
    [bottomRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:CGRectOffset(self.bottomRight.frame, timeForPage(2), 0)]];
    [bottomRightFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(CGRectInset(self.bottomRight.frame,kDs,kDs), timeForPage(3), kDy)]];
    
    
    //******************************************************
    // now, we animate the bottomRightLabel
    //******************************************************
    
    //    [self createAnimationWithDictionary:@{@"Label":self.bottomRightLabel,
    //                                          @"KeyFrame1":@[@1,@0],
    //                                          @"KeyFrame2":@[@2,@1],
    //                                          @"KeyFrame3":@[@3,@1],
    //                                          @"KeyFrame4":@[@4,@0]
    //                                          }];
    
//    - (IFTTTAlphaAnimation *)createAnimationWithDictionary:(NSDictionary* )dict{
//        IFTTTAlphaAnimation *labelAlphaAnimation = [IFTTTAlphaAnimation animationWithView:[dict objectForKey:@"Label"]];
//        for (IFTTTAnimationKeyFrame *kf in dict) {
//            if([[dict objectForKey:kf] isKindOfClass:[NSArray class]]){
//                int page = ((int)[dict objectForKey:kf][0]);
//                int alpha = ((int)[dict objectForKey:kf][1]);
//                [labelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(page) andAlpha:alpha]];
//            }
//        }
//        [self.animator addAnimation:labelAlphaAnimation];
//        return labelAlphaAnimation;
//    }
    

    
    

    
    
   
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
    //fade all the Label in on page 2 and out on page 4
    //******************************************************
    IFTTTAlphaAnimation *topLeftLabelAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.topLeftLabel];
    [self.animator addAnimation:topLeftLabelAlphaAnimation];
    
    [topLeftLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andAlpha:0.0f]];
    [topLeftLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:1.0f]];
    [topLeftLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:1.0f]];
    [topLeftLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:0.0f]];
    
    IFTTTAlphaAnimation *topRightLabelAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.topRightLabel];
    [self.animator addAnimation:topRightLabelAlphaAnimation];
    
    [topRightLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andAlpha:0.0f]];
    [topRightLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:1.0f]];
    [topRightLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:1.0f]];
    [topRightLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:0.0f]];
    
//    IFTTTAlphaAnimation *bottomLeftLabelAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.bottomLeftLabel];
//    [self.animator addAnimation:bottomLeftLabelAlphaAnimation];
//    
//    [bottomLeftLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andAlpha:0.0f]];
//    [bottomLeftLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:1.0f]];
//    [bottomLeftLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:1.0f]];
//    [bottomLeftLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:0.0f]];
    
// Attempting to refactor anamations
    //    IFTTTAlphaAnimation *bottomRightLabelAlphaAnimation = JCAnimation[bottomRightLabelAlphaAnimation, self.bottomRightLabel,0.0f,1.0f,1.0f,0.0f];
    
//    IFTTTAlphaAnimation *bottomRightLabelAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.bottomRightLabel];
//    [self.animator addAnimation:bottomRightLabelAlphaAnimation];
//    
//    [bottomRightLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andAlpha:0.0f]];
//    [bottomRightLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:1.0f]];
//    [bottomRightLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:1.0f]];
//    [bottomRightLabelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:0.0f]];
    [self createAnimationWithDictionary:@{@"Label":self.bottomLeftLabel,
                                          @"KeyFrame1":@[@1,@0],
                                          @"KeyFrame2":@[@2,@1],
                                          @"KeyFrame3":@[@3,@1],
                                          @"KeyFrame4":@[@4,@0]
                                          }];
    
    [self createAnimationWithDictionary:@{@"Label":self.bottomRightLabel,
                                          @"KeyFrame1":@[@1,@0],
                                          @"KeyFrame2":@[@2,@1],
                                          @"KeyFrame3":@[@3,@1],
                                          @"KeyFrame4":@[@4,@0]
                                          }];
    
    //    IFTTTFrameAnimation *bottomRightLabelFrameAnimation = [IFTTTFrameAnimation animationWithView:self.bottomRightLabel];
    //    [self.animator addAnimation:bottomRightLabelFrameAnimation];
    //
    //    CGRect bottomRightLabelStartFrame = CGRectOffset(self.bottomRightLabel.frame, (self.view.frame.size.width - self.bottomRightLabel.frame.size.width), 0);
    //    [bottomRightLabelFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:bottomRightLabelStartFrame]];
    //    [bottomRightLabelFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:CGRectOffset(self.bottomRightLabel.frame, timeForPage(2), 0)]];
    //    [bottomRightLabelFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(CGRectInset(self.bottomRightLabel.frame,kDs,kDs), timeForPage(3), kDy)]];
    //
    
    self.bottomRightLabel.frame = CGRectOffset(self.bottomRightLabel.frame, (self.view.frame.size.width - self.bottomRightLabel.frame.size.width), 0);
    [self createFrameAnimationWithDictionaryOfKeyFramesAndTime:@{@"Label":self.bottomRightLabel,
                                                                 @"KeyFrame1":@[@1,@0],
                                                                 @"KeyFrame2":@[@2,@0],
                                                                 @"KeyFrame3":@[@3,@(kDy)]
                                                                 }];
    
}
//TODO:Fixthis 
- (IFTTTFrameAnimation *)createFrameAnimationWithDictionaryOfKeyFramesAndTime:(NSDictionary* )anotherDict{
    IFTTTFrameAnimation *frameAnimation = [IFTTTFrameAnimation animationWithView:[anotherDict objectForKey:@"Label"]];
    for (IFTTTFrameAnimation *kfa in anotherDict) {
        if([[anotherDict objectForKey:kfa] isKindOfClass:[NSArray class]]){
            int page = ((int)[anotherDict objectForKey:kfa][0]);
            int offset = ((int)[anotherDict objectForKey:kfa][1]);
            CGRect frame = ((UILabel *)[anotherDict objectForKey:@"Label"]).frame;
            [frameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(page) andFrame:CGRectOffset(frame, timeForPage(page), offset)]];
        }
    }
    [self.animator addAnimation:frameAnimation];
    return frameAnimation;
}
           

- (IFTTTAlphaAnimation *)createAnimationWithDictionary:(NSDictionary* )dict{
    IFTTTAlphaAnimation *labelAlphaAnimation = [IFTTTAlphaAnimation animationWithView:[dict objectForKey:@"Label"]];
    for (IFTTTAnimationKeyFrame *kf in dict) {
        if([[dict objectForKey:kf] isKindOfClass:[NSArray class]]){
            int page = ((int)[dict objectForKey:kf][0]);
            int alpha = ((int)[dict objectForKey:kf][1]);
            [labelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(page) andAlpha:alpha]];
        }
    }
    [self.animator addAnimation:labelAlphaAnimation];
    return labelAlphaAnimation;
}

#pragma mark - page3
    - (void)setupPage3
    {
    //******************************************************
    //add Get Started button to page3
    //******************************************************
//    JCGetStartedButton *gft = [[JCGetStartedButton alloc]initWithFrame:self.getStartedButton.imageView.frame];
//    self.getStartedButton.imageView.image = ((UIImage*)gft);
//    [self.getStartedButton setBackgroundImage:[JCStyleKit imageOfGetStartedButtonWithFrame:self.getStartedButton.frame] forState:UIControlStateNormal];
    self.getStartedButton.center = self.view.center;
    self.getStartedButton.frame = CGRectOffset(self.getStartedButton.frame, kgetStartedButton_x, kgetStartedButton_y);
    [self.getStartedButton setAlpha:1.0];
    [self.scrollView addSubview:self.getStartedButton];
    }
#pragma mark - page4
        - (void)setupPage4
        {
    UILabel *comingSoon = [[UILabel alloc] init];
    comingSoon.text = @"Coming soon!";
    [comingSoon setFont:[UIFont fontWithName:kIntroFont size:40]];
    comingSoon.textColor = [UIColor whiteColor];
    comingSoon.shadowColor = [UIColor darkGrayColor];
    comingSoon.shadowOffset = CGSizeMake(0, 1);
    [comingSoon sizeToFit];
    comingSoon.center = self.view.center;
    comingSoon.frame = CGRectOffset(comingSoon.frame, timeForPage(4), -55);
    [self.scrollView addSubview:comingSoon];
    self.thridPageLabel1 = comingSoon;

     //******************************************************
    // Fade out the label by dragging on the last page
    //******************************************************
    IFTTTAlphaAnimation *labelAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.lastLabel];
    [labelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:1.0f]];
    [labelAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4.35f) andAlpha:0.0f]];
    [self.animator addAnimation:labelAlphaAnimation];
}
#pragma mark - convience methods

//awesomeShadow for the voicemail veiw that gives us depth
- (CGPathRef)awesomeShadow:(CGRect)rect
{
    CGSize size = rect.size;
    size.height  = size.height - 2.0f;
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    [path moveToPoint:CGPointMake(5, 10.0f)];//top left corner of shadow
    [path addLineToPoint:CGPointMake(size.width, 10.0f)]; //top right corner of shadow
    [path addLineToPoint:CGPointMake(size.width, size.height - 1.0f)];//bottom right the size.height + 10 is the determinate of how far down the corners are
    
    [path addCurveToPoint:CGPointMake(2.0f, size.height - 1.0f) //bottom left
            controlPoint1:CGPointMake(size.width - 15.0f, size.height - 8.0f) // curve control
            controlPoint2:CGPointMake(15.0f, size.height - 8.0f)]; // curve control
    
    return path.CGPath;
}

#pragma mark - IFTTTAnimatedScrollViewControllerDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [super scrollViewDidScroll:scrollView];
    
    if (self.pageControlDots.currentPage != 0 && scrollView.contentOffset.x < 160)
    {
        [self.pageControlDots setCurrentPage:0];
    }
    if(self.pageControlDots.currentPage != 1 && scrollView.contentOffset.x > 160 && scrollView.contentOffset.x < 480)
    {
        [self.pageControlDots setCurrentPage:1];
    }
    if(self.pageControlDots.currentPage != 2 && scrollView.contentOffset.x > 480)
    {
        [self.pageControlDots setCurrentPage:2];
    }

}

- (IBAction)getStartedButtonWasTapped:(id)sender {    [self dismissViewControllerAnimated:NO completion:^{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AppTutorialDismissed" object:nil];
}];
    //Register for PushNotifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                           UIRemoteNotificationTypeBadge |
                                                                           UIRemoteNotificationTypeSound)];
}


@end
