//
//  JCContactsHomeViewController.h
//  JiveOne
//
//  Created by Eduardo  Gueiros on 11/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

@class ContactGroup;

@interface JCContactsViewController : UIViewController <UITabBarDelegate>

@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet UITabBar *tabBar;

@property (nonatomic, strong) ContactGroup *contactGroup;

@end
