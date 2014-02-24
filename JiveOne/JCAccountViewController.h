//
//  JCAccountViewController.h
//  JiveOne
//
//  Created by Daniel George on 2/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCAccountViewController : UITableViewController <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UILabel *userNameDetail;
@property (weak, nonatomic) IBOutlet UILabel *pbxDetail;
@property (weak, nonatomic) IBOutlet UILabel *companyNameDetail;
@property (weak, nonatomic) IBOutlet UILabel *presenceDetail;

@end
