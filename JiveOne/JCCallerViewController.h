//
//  JCCallerViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCCallCardListView.h"

@class JCCallerViewController;

@protocol JCCallerViewControllerDelegate <NSObject>

-(void)shouldDismissCallerViewController:(JCCallerViewController *)viewController;

@end

@interface JCCallerViewController : UIViewController

@property (nonatomic, weak) IBOutlet id<JCCallerViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet JCCallCardListView *callCardList;

@property (nonatomic, strong) NSString *dialString;

-(IBAction)warmTransfer:(id)sender;
-(IBAction)blindTransfer:(id)sender;
-(IBAction)speaker:(id)sender;
-(IBAction)keypad:(id)sender;
-(IBAction)addCall:(id)sender;
-(IBAction)mute:(id)sender;

@end
