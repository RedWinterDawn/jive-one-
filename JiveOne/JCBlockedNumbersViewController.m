//
//  JCBlockedNumbersViewController.m
//  JiveOne
//
//  Created by P Leonard on 5/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBlockedNumbersViewController.h"

#import <JCPhoneModule/JCProgressHUD.h>

#import "JCUserManager.h"
#import "BlockedNumber+V5Client.h"
#import "PBX.h"

@interface JCBlockedNumbersViewController ()

@end

@implementation JCBlockedNumbersViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    PBX *pbx = self.userManager.pbx;
    [BlockedNumber downloadBlockedForDIDs:pbx.dids completion:NULL];
}

-(NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        
        PBX *pbx = self.userManager.pbx;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"did.pbx = %@", pbx];
        NSFetchRequest *fetchRequest = [BlockedNumber MR_requestAllWithPredicate:predicate];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES]];
        super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                             managedObjectContext:self.managedObjectContext
                                                                               sectionNameKeyPath:@"did.titleText"
                                                                                        cacheName:nil];
    }
    return _fetchedResultsController;
}

-(void)configureCell:(UITableViewCell *)cell withObject:(BlockedNumber *)blockedNumber
{
    cell.textLabel.text = blockedNumber.detailText;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    
    return sectionInfo.name;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Unblock";
}

-(void)deleteObject:(BlockedNumber *)blockedNumber
{
    [BlockedNumber unblockNumber:blockedNumber completion:NULL];
}

-(IBAction)refeshTable:(id)sender
{
    if ([sender isKindOfClass:[UIRefreshControl class]]) {
        PBX *pbx = self.userManager.pbx;
        [BlockedNumber downloadBlockedForDIDs:pbx.dids
                                   completion:^(BOOL success, NSError *error) {
                                       [((UIRefreshControl *)sender) endRefreshing];
                                       if (!success) {
                                           [self showError:error];
                                       }
                                   }];
    }
}

@end
