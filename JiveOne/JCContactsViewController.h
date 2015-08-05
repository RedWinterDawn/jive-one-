//
//  JCContactsHomeViewController.h
//  JiveOne
//
//  Created by Eduardo  Gueiros on 11/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

#import "JCGroupDataSource.h"

@interface JCContactsViewController : UIViewController <UITabBarDelegate>

@property (nonatomic, strong) id<JCGroupDataSource> group;

@end
