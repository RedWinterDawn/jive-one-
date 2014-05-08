//
//  JCContainerViewController.m
//  JiveOne
//
//  Created by Doug on 5/5/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAppDelegate.h"
#import "JCContainerViewController.h"
#import "JCPage1ViewController.h"
#import "JCPage2ViewController.h"
#import "JCPage3ViewController.h"
#import "JCPage4ViewController.h"


@interface JCContainerViewController ()
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) UIViewController *vc;
@property (strong, nonatomic) JCPage1ViewController *page1;
@property (strong, nonatomic) JCPage2ViewController *page2;
@property (strong, nonatomic) JCPage3ViewController *page3;
@property (strong, nonatomic) JCPage4ViewController *page4;
@property (nonatomic) NSArray* pages;
@property (nonatomic) NSInteger* currentIndex;
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
    // Do any additional setup after loading the view.
    // Create page view controller
    
    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"JCPageViewController"];
    self.pageViewController.dataSource = self;
    
    NSArray *viewControllers = @[self.page1];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    // Change the size of page view controller
    self.pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 30);
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
    //never show the intro again...
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"seenAppTutorial"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger *)currentIndex
{
    if (!_currentIndex) {
        _currentIndex = 0;
    }
    return _currentIndex;
}
-(NSArray *)pages
{
    if (!_pages) {
        _pages =@[self.page1, self.page2, self.page3, self.page4];
    }
    return _pages;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(JCPage1ViewController*)page1
{
    if (!_page1) {
        _page1 = [self.storyboard instantiateViewControllerWithIdentifier:@"JCPage1ViewController"];

    }
    return _page1;
}
-(JCPage2ViewController*)page2
{
    if (!_page2) {
        _page2 = [self.storyboard instantiateViewControllerWithIdentifier:@"JCPage2ViewController"];
    }
    return _page2;
}
-(JCPage3ViewController*)page3
{
    if (!_page3) {
        _page3 = [self.storyboard instantiateViewControllerWithIdentifier:@"JCPage3ViewController"];
    }
    return _page3;
}
-(JCPage4ViewController*)page4
{
    if (!_page4) {
        _page4 = [self.storyboard instantiateViewControllerWithIdentifier:@"JCPage4ViewController"];
    }
    return _page4;
}



- (JCPageClass *)viewControllerAtIndex:(NSUInteger)index
{
//    if (([self.pageTitles count] == 0) || (index >= [self.pageTitles count])) {
//        return nil;
//    }
    
    // Create a new view controller and pass suitable data.
    JCPageClass *pageContentViewController;
    
    switch (index) {
        case 0:
            pageContentViewController = (JCPageClass *)self.page1;
            
            break;
        case 1:
            pageContentViewController = (JCPageClass *)self.page2;
            break;
        case 2:
            pageContentViewController = (JCPageClass *)self.page3;

            break;
        case 3:
            pageContentViewController = (JCPageClass *)self.page4;
            
            break;
    }
    
    return pageContentViewController;
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    
    NSUInteger index = [self.pages indexOfObject:viewController];
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self.pages indexOfObject:viewController];
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == 4) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return 4;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}


- (void)goToApplication
{
    [self performSegueWithIdentifier: @"TutorialToTabBarSegue" sender: self];
}

- (IBAction)dismissButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AppTutorialDismissed" object:nil];
            }];
    //Register for PushNotifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                           UIRemoteNotificationTypeBadge |
                                                                           UIRemoteNotificationTypeSound)];
}
@end
