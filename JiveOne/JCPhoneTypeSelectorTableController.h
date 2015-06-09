//
//  JCPhoneTypeSelectorTableController.h
//  JiveOne
//
//  Created by P Leonard on 6/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCPhoneTypeSelectorTableController : UITableViewController
@property (strong, nonatomic) IBOutlet UITableView *phoneTypes;
@property (strong, nonatomic) IBOutlet NSString *selectedType;


@end
