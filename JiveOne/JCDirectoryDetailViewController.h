//
//  JCDirectoryDetailViewController.h
//  JiveOne
//
//  Created by Doug Leonard on 2/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClientEntities.h"


@interface JCDirectoryDetailViewController : UITableViewController

@property (strong, nonatomic) ClientEntities *person;

@end