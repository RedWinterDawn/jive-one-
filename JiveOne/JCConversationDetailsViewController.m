//
//  JCConversationDetailsViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 5/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationDetailsViewController.h"

#import <JCPhoneModule/JCProgressHUD.h>

#import "JCMessageGroup.h"
#import "DID.h"
#import "BlockedNumber+V5Client.h"
#import "SMSMessage.h"

@interface JCConversationDetailsViewController ()

@property (nonatomic, weak) IBOutlet UITableViewCell *phoneNumberCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *blockNumberCell;
@property (nonatomic, weak) IBOutlet UISwitch *blockSwitch;

@end

@implementation JCConversationDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    JCMessageGroup *messageGroup = self.conversationGroup;
    
    NSString *name = messageGroup.phoneNumber.name;
    self.phoneNumberCell.textLabel.text = name ? name : NSLocalizedString(@"Unknown", nil);
    self.phoneNumberCell.detailTextLabel.text = messageGroup.phoneNumber.formattedNumber;
    
    [self cell:self.blockNumberCell setHidden:!messageGroup.isSMS];
    
    BlockedNumber *blockedNumber = [BlockedNumber blockedNumberForMessageGroup:messageGroup context:[NSManagedObjectContext MR_defaultContext]];
    self.blockSwitch.on = (blockedNumber != nil);
    
    [self reloadDataAnimated:NO];
}

- (void)toggleBlock:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]]) {
        JCMessageGroup *messageGroup = self.conversationGroup;
        Message *message = messageGroup.latestMessage;
        if (![message isKindOfClass:[SMSMessage class]]) {
            return;
        }
        
        SMSMessage *smsMessage = (SMSMessage *)message;
        UISwitch *blockSwitch = (UISwitch *)sender;
        BlockedNumber *blockedNumber = [BlockedNumber blockedNumberForMessageGroup:messageGroup context:[NSManagedObjectContext MR_defaultContext]];
        if (blockedNumber) {
            [BlockedNumber unblockNumber:blockedNumber completion:^(BOOL success, NSError *error) {
                if (success) {
                    blockSwitch.on = FALSE;
                } else {
                    [self showError:error];
                }
            }];
        } else {
            [BlockedNumber blockNumber:messageGroup.phoneNumber did:smsMessage.did completion:^(BOOL success, NSError *error) {
                if (success) {
                    blockSwitch.on = TRUE;
                } else {
                    [self showError:error];
                }
            }];
        }
    }
}

@end
