//
//  JCLoginViewController.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/11/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCOsgiClient.h"

@interface JCLoginViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UILabel *loginStatusLabel;
@property (nonatomic) BOOL seenTutorial;
@property (nonatomic) BOOL doneLoadingContent;
@property (nonatomic) BOOL userIsDoneWithTutorial;
@property (nonatomic) JCOsgiClient *client;
@property (weak, nonatomic) IBOutlet UIView *loginViewContainer;


- (void)goToApplication;
- (IBAction)termsAndConditionsButton:(id)sender;
- (void)fetchEntities;
- (void)fetchCompany;
- (void)fetchPresence;
- (void)fetchConversations;
- (void)fetchVoicemails;
@end
