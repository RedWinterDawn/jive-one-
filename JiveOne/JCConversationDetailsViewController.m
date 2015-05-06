//
//  JCConversationDetailsViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 5/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationDetailsViewController.h"
#import "JCSMSConversationGroup.h"
#import "DID.h"
#import "BlockedNumber+V5Client.h"

@interface JCConversationDetailsViewController ()

@end

@implementation JCConversationDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    id<JCConversationGroupObject> conversationGroup = self.conversationGroup;
    
    NSString *name = conversationGroup.name;
    self.phoneNumberCell.textLabel.text = name ? name : NSLocalizedString(@"Unknown", nil);
    self.phoneNumberCell.detailTextLabel.text = self.conversationGroup.formattedNumber;
    
    [self cell:self.blockNumberCell setHidden:!conversationGroup.isSMS];
    
    BlockedNumber *blockedNumber = [BlockedNumber blockedNumberForConversationGroup:conversationGroup context:[NSManagedObjectContext MR_defaultContext]];
    self.blockSwitch.on = (blockedNumber != nil);
    
    [self reloadDataAnimated:NO];
}

- (void)toggleBlock:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]]) {
        id<JCConversationGroupObject> conversationGroup = self.conversationGroup;
        UISwitch *blockSwitch = (UISwitch *)sender;
        BlockedNumber *blockedNumber = [BlockedNumber blockedNumberForConversationGroup:conversationGroup context:[NSManagedObjectContext MR_defaultContext]];
        if (blockedNumber) {
            [BlockedNumber unblockNumber:blockedNumber completion:^(BOOL success, NSError *error) {
                if (success) {
                    blockSwitch.on = FALSE;
                } else {
                    [self showError:error];
                }
            }];
        } else {
            DID *did = [DID MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:((JCSMSConversationGroup *)conversationGroup).didJrn];
            [BlockedNumber blockNumber:conversationGroup did:did completion:^(BOOL success, NSError *error) {
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
