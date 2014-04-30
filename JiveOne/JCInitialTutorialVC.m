//
//  JCInitialTutorialVC.m
//  JiveOne
//
//  Created by Doug on 4/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCInitialTutorialVC.h"

@interface JCInitialTutorialVC ()

@end

@implementation JCInitialTutorialVC
CATextLayer *text1;
UILabel *headingLabel2;

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
    
    // Create the data model
    _pageTitles = @[@"Welcome To Jive", @"Message Colleagues", @"Check Voicemail", @"Be In 'The Know'"];

    // Create page view controller
    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
    self.pageViewController.dataSource = self;
    
    JCTutorialContentViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    // Change the size of page view controller
    self.pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 30);
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
    headingLabel2.userInteractionEnabled = YES;
    for (UIView *view in self.pageViewController.view.subviews) {
        if ([view isKindOfClass:[UIScrollView class]]) {
            [(UIScrollView *)view setDelegate:self];
        }
    }

}

- (void)didchangePosition:(NSNotification *)notification
{
    
    headingLabel2.center = CGPointMake(headingLabel2.center.x + (self.percentage * 100),headingLabel2.center.y);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (JCTutorialContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if (([self.pageTitles count] == 0) || (index >= [self.pageTitles count])) {
        return nil;
    }
    
    // Create a new view controller and pass suitable data.
    JCTutorialContentViewController *pageContentViewController;
    
    switch (index) {
        case 0:
            pageContentViewController = [self configurePageZero];
            break;
        case 1:
            pageContentViewController = [self configurePageOne];
            break;
        case 2:
            pageContentViewController = [self configurePageTwo];
            break;
        case 3:
            pageContentViewController = [self configurePageThree];
            break;
    }
    
    
    
    
    return pageContentViewController;
}

-(JCTutorialContentViewController *)configurePageZero
{
    // Create a new view controller and pass suitable data.
    JCTutorialContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"JCTutorialContentViewController"];
    pageContentViewController.titleText = self.pageTitles[0];
    pageContentViewController.pageIndex = 0;
    
    UILabel *headingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 240, 300, 30)];
    headingLabel.text = @"WELCOME0";
    headingLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:14.0];
    UILabel *headingLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(100, 240, 300, 30)];
    headingLabel2.text = @"Something Else";
    headingLabel2.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:14.0];

    [pageContentViewController.view addSubview:headingLabel];
    [pageContentViewController.view addSubview:headingLabel2];
    
    return pageContentViewController;
}

-(JCTutorialContentViewController *)configurePageOne
{
    // Create a new view controller and pass suitable data.
    JCTutorialContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"JCTutorialContentViewController"];
    pageContentViewController.titleText = self.pageTitles[1];
    pageContentViewController.pageIndex = 1;
    
    UILabel *headingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 240, 300, 30)];
    headingLabel.text = @"WELCOME1";
    headingLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:14.0];
    
    headingLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(100, 290, 300, 30)];
    headingLabel2.text = @"Really Cool Feature";
    headingLabel2.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:14.0];
//    text1 = [self createCATextLayerAtPosition:CGPointMake(100, 290) UsingString:@"Really Cool Feature"];
    
    [pageContentViewController.view addSubview:headingLabel];
    [pageContentViewController.view addSubview:headingLabel2];

    
//    [pageContentViewController.view.layer addSublayer:text1];
//    [self animateLayer:text1 InAStraightLineToEndPoint:CGPointMake(10, 290)];
    return pageContentViewController;
}

-(JCTutorialContentViewController *)configurePageTwo
{
    // Create a new view controller and pass suitable data.
    JCTutorialContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"JCTutorialContentViewController"];
    pageContentViewController.titleText = self.pageTitles[2];
    pageContentViewController.pageIndex = 2;
    
    UILabel *headingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 240, 300, 30)];
    headingLabel.text = @"WELCOME2";
    headingLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:14.0];
    
    [pageContentViewController.view addSubview:headingLabel];
    
    
    return pageContentViewController;
}

-(JCTutorialContentViewController *)configurePageThree
{
    // Create a new view controller and pass suitable data.
    JCTutorialContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"JCTutorialContentViewController"];
    pageContentViewController.titleText = self.pageTitles[3];
    pageContentViewController.pageIndex = 3;
    
    UILabel *headingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 240, 300, 30)];
    headingLabel.text = @"WELCOME3";
    headingLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:14.0];
    
    [pageContentViewController.view addSubview:headingLabel];
    
    return pageContentViewController;
}


#pragma mark - Animation


-(CATextLayer *)createCATextLayerAtPosition:(CGPoint)position UsingString:(NSString *)string
{
    UIFont *font = [UIFont fontWithName:@"Helvetica" size:30];
    NSDictionary *userAttributes = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName: [UIColor blackColor]};
    
    CGSize textSize = [string sizeWithAttributes:userAttributes];
    CATextLayer *label = [[CATextLayer alloc]init];
    [label setFont:@"Helvetica-Bold"];
    [label setFontSize:20];
    [label setFrame:CGRectMake(position.x, position.y, textSize.width, textSize.height)];
    [label setString:string];
    [label setAlignmentMode:kCAAlignmentCenter];
    [label setForegroundColor:[[UIColor blackColor] CGColor]];
//    [self.view.layer addSublayer:label];

    return label;
}



-(void)animateLayer:(CALayer*)layer InAStraightLineToEndPoint:(CGPoint)endPoint
{
    
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: layer.position];
    endPoint.x = endPoint.x + (layer.frame.size.width/2);
    endPoint.y = endPoint.y + (layer.frame.size.height/2);
    [bezierPath addLineToPoint: endPoint];
//    CGPoint translation = [classGestureRecognizer translationInView:self.view];
    
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    anim.path = bezierPath.CGPath;
    //    anim.fillMode = kCAFillModeForwards;
    anim.rotationMode = kCAAnimationLinear;
    anim.speed = 0.0;
    anim.removedOnCompletion = NO;
    anim.beginTime = 0.0;
    anim.timeOffset = self.percentage;
    NSLog(@"%f,%f,%f",self.percentage, layer.position.x, layer.position.y);
    anim.duration = 1.0;
    [layer addAnimation:anim forKey:@"moveObject"];
    
}





#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((JCTutorialContentViewController*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((JCTutorialContentViewController*) viewController).pageIndex;
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.pageTitles count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

//need to determine if the view offset value is positive or negitive based on the previous value. for springback...
    if (scrollView.contentOffset.x > 319 && scrollView.contentOffset.x < 321) {
        NSLog(@"*********");
    }else if(scrollView.contentOffset.x < 319)
    {
        //range is 0 - 319
        //scale is 319
        CGFloat percentage = (scrollView.contentOffset.x / 319);
        percentage = (percentage < .000001) ? .000001 : percentage;
        self.percentage = percentage;
        NSLog(@"< 319: %f : %f", scrollView.contentOffset.x, percentage );
        headingLabel2.frame = CGRectMake(headingLabel2.frame.origin.x + (self.percentage), headingLabel2.frame.origin.y, headingLabel2.frame.size.width, headingLabel2.frame.size.height);
        NSLog(@"%f",headingLabel2.frame.origin.x);
    }else if (scrollView.contentOffset.x > 321){
        //range is 321 - 640
        //scale is 319
        CGFloat percentage = ((scrollView.contentOffset.x - 319) / 321);
        percentage = (percentage > .999999) ? .999999 : percentage;
        self.percentage = percentage;
        
        NSLog(@"> 321: %f : %f", scrollView.contentOffset.x, percentage );
        headingLabel2.frame = CGRectMake(headingLabel2.frame.origin.x - (self.percentage), headingLabel2.frame.origin.y, headingLabel2.frame.size.width, headingLabel2.frame.size.height);
        
        NSLog(@"%f",headingLabel2.frame.origin.x);

    }
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.pageTitles count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}

- (IBAction)startButton:(id)sender {
    JCTutorialContentViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionReverse animated:NO completion:nil];
}
@end
