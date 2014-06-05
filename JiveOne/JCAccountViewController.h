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
@property (weak, nonatomic) IBOutlet UILabel *jivePhoneNumber;
@property (weak, nonatomic) IBOutlet UILabel *jiveMessenger;
@property (weak, nonatomic) IBOutlet UILabel *presenceDetail;
@property (weak, nonatomic) IBOutlet JCPresenceView *presenceDetailView;

@end
