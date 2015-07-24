//
//  JCSwitchTableViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 7/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCSwitchTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UISwitch *switchBtn;

@property (nonatomic) BOOL enabled;

@end
