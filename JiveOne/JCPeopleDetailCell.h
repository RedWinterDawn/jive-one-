//
//  JCPeopleDetailCell.h
//  JiveOne
//
//  Created by Doug Leonard on 4/7/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCPresenceView.h"

@interface JCPeopleDetailCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *NameLabel;
@property (strong, nonatomic) IBOutlet JCPresenceView *presenceView;
@property (nonatomic) ClientEntities *person;
@end
