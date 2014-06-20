		//
//  JCAccountViewController.h
//  JiveOne
//
//  Created by Daniel George on 2/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCPresenceViewController.h"
#import "JCPresenceView.h"

@interface JCAccountViewController : UITableViewController <UIActionSheetDelegate, JCPresenceDelegate>

@property (weak, nonatomic) IBOutlet UILabel *userNameDetail;
@property (weak, nonatomic) IBOutlet UILabel *userTitleDetail;
@property (weak, nonatomic) IBOutlet UILabel *presenceDetail;
@property (weak, nonatomic) IBOutlet JCPresenceView *presenceDetailView;
@property (weak, nonatomic) IBOutlet UIImageView *userImage;
@property (weak, nonatomic) IBOutlet UITextField *userMoodDetail;
@property (weak, nonatomic) IBOutlet UIImageView *logoutImageView;
@property (weak, nonatomic) IBOutlet UIImageView *eulaImageView;
@property (weak, nonatomic) IBOutlet UIImageView *feedbackImageView;

@property (weak, nonatomic) IBOutlet UIView *presenceAccessory;
@end
