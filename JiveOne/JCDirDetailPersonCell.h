//
//  JCDirDetailPersonCell.h
//  JiveOne
//
//  Created by Doug Leonard on 4/4/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCPresenceView.h"

@interface JCDirDetailPersonCell : UITableViewCell
@property (weak, nonatomic) IBOutlet JCPresenceView *presenceView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end
