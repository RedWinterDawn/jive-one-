//
//  JCContainerViewController.m
//  JiveOne
//
//  Created by Doug on 5/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCContainerViewController.h"
#import "JCAppDelegate.h"
#import "JCPage1ViewController.h"

@interface JCContainerViewController ()
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) NSMutableArray *arrayOfPageViewControllers;
@end

@implementation JCContainerViewController

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
    self.pageViewController.dataSource = self;
    

}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offset = scrollView.contentOffset.x;
    
        CGFloat pullOffset = MAX(0, offset);
        [_delegate scrollingDidChangePullOffset:pullOffset];
    
    if (scrollView.contentOffset.x > 319 && scrollView.contentOffset.x < 321) {
        NSLog(@"*********");
    }else if(scrollView.contentOffset.x < 319)
    {
        //range is 0 - 319
        //scale is 319
        CGFloat percentage = (scrollView.contentOffset.x / 319);
        percentage = (percentage < .000001) ? .000001 : percentage;
        
        self.percentDoneOfAnimationProgress = percentage;
        
        NSLog(@"Offset<: %f : %f", scrollView.contentOffset.x, percentage );
//        self.anchor = CGPointMake(self.anchor.x + (self.percentDoneOfAnimationProgress), self.anchor.y);
        
//        NSLog(@"anchor.x : %f frame.orgin.x : %f", self.anchor.x, self.headingLabel2.frame.origin.x);
        
//        [self.attachment setAnchorPoint:self.anchor];
        
        
        
    }else if (scrollView.contentOffset.x > 321){
        //range is 321 - 640
        //scale is 319
        CGFloat percentage = ((scrollView.contentOffset.x - 319) / 321);
        percentage = (percentage > .999999) ? .999999 : percentage;
        self.percentDoneOfAnimationProgress = percentage;
        NSLog(@"Offset>: %f : %f", scrollView.contentOffset.x, percentage );
//        self.anchor = CGPointMake(self.anchor.x - (self.percentDoneOfAnimationProgress), self.anchor.y);
//        [self.attachment setAnchorPoint:self.anchor];
        
//        NSLog(@"anchor.x : %f frame.orgin.x : %f", self.anchor.x, self.headingLabel2.frame.origin.x);
        
    }

    
    
}


#pragma mark - Page1Delegate

- (void)scrollingDidChangePullOffset:(CGFloat)offset
{
    
    
    
    
}



#pragma mark - properties

- (NSArray*)arrayOfPageViewControllers{
    if (!_arrayOfPageViewControllers) {
        _arrayOfPageViewControllers = [[NSMutableArray alloc]init];
        
        NSArray *pagesStoryBoardIDs = @[@"Page1", @"Page2", @"Page3", @"Page4"];
        
        for (NSString *index in pagesStoryBoardIDs) {
            JCPage1ViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier: index];
//            viewController.delegate = self;
            
            [_arrayOfPageViewControllers addObject: viewController];
        }
    }
    return  _arrayOfPageViewControllers;
}


-(UIViewController*)pageViewController
{
    if (!_pageViewController) {
       _pageViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"PageVC"];
        [_pageViewController setViewControllers:self.arrayOfPageViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
        //change size of pageVC
        _pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 30);
        [self addChildViewController:_pageViewController];
        [self.view addSubview:_pageViewController.view];
        [_pageViewController didMoveToParentViewController:self];
        for (UIView *view in self.pageViewController.view.subviews) {
            if ([view isKindOfClass:[UIScrollView class]]) {
                [(UIScrollView *)view setDelegate:self];
            }
        }
    }
    return _pageViewController;
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if (index >= [self.arrayOfPageViewControllers count]) {
        return nil;
    }
    
    return self.arrayOfPageViewControllers[index];
}

- (CGFloat)percentDoneOfAnimationProgress
{
    if (!self.percentDoneOfAnimationProgress) {
        self.percentDoneOfAnimationProgress = 0.0;
    }
    return self.percentDoneOfAnimationProgress;
}

-(void)setPercentDoneOfAnimationProgress:(CGFloat)percentDoneOfAnimationProgress
{
    self.percentDoneOfAnimationProgress = percentDoneOfAnimationProgress;
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self.arrayOfPageViewControllers indexOfObject:viewController];
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self.arrayOfPageViewControllers indexOfObject:viewController];
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.arrayOfPageViewControllers count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    
//    //need to determine if the view offset value is positive or negitive based on the previous value. for springback..
//    
//    
//    if (scrollView.contentOffset.x > 319 && scrollView.contentOffset.x < 321) {
//        NSLog(@"*****0*****");
//    }else if(scrollView.contentOffset.x < 319)
//    {
//        //range is 0 - 319
//        //scale is 319
//        CGFloat percentage = (scrollView.contentOffset.x / 319);
//        percentage = (percentage < .000001) ? .000001 : percentage;
//        self.percentDoneOfAnimationProgress = percentage;
//        
//        
//        
//        
//    }else if (scrollView.contentOffset.x > 321){
//        //range is 321 - 640
//        //scale is 319
//        CGFloat percentage = ((scrollView.contentOffset.x - 319) / 321);
//        percentage = (percentage > .999999) ? .999999 : percentage;
//        self.percentDoneOfAnimationProgress = percentage;
//        
//        
//    }
//}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.arrayOfPageViewControllers count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.arrayOfPageViewControllers count];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
