//
//  JCGroupSelectorViewController.h
//  JiveOne
//
//  Created by Ethan Parker on 3/4/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PersonEntities.h"
#import "ContactGroup.h"
#import "PBX+Custom.h"

@interface JCGroupSelectorViewController : UITableViewController <UIAlertViewDelegate>

@property (nonatomic, strong) NSMutableArray *companyContactsArray;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSMutableArray *contactGroupArray;
@property (nonatomic, strong) ContactGroup *groupEdit;
@property (nonatomic, strong) PBX *pbxEdit;

@end
