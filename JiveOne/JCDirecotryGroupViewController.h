//
//  JCDirecotryGroupViewController.h
//  JiveOne
//
//  Created by Ethan Parker on 2/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClientEntities.h"

@interface JCDirecotryGroupViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *person;
@property (nonatomic, strong) NSMutableArray *personDict;
@property (nonatomic, weak) NSNumber *contactGroup;

@end
