//
//  JCHistoryCell.h
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCHistoryCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *name;
@property (weak, nonatomic) IBOutlet UIView *Number;
@property (weak, nonatomic) IBOutlet UIView *exstention;
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;

@end
