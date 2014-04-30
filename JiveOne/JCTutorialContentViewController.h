//
//  JCTutorialContentViewController.h
//  JiveOne
//
//  Created by Doug on 4/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCTutorialContentViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property NSUInteger pageIndex;
@property NSString *titleText;
@end
