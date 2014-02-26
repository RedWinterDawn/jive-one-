//
//  JCPersonCell.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCPersonCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *personNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *personDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *personPresenceLabel;
@property (weak, nonatomic) IBOutlet UIImageView *personPicture;
@property (strong, nonatomic) NSString *personId;
@end
