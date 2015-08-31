//
//  JCMessageParticipantViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 2/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMessageParticipantTableViewController.h"
#import "JCPhoneBook.h"
#import "JCUnknownNumber.h"
#import "JCMessageGroup.h"
#import "Extension.h"
#import "PhoneNumber.h"
#import "Contact.h"
#import "PBX.h"
#import "JCPhoneNumberUtils.h"
#import "DID.h"

@interface JCMessageParticipantTableViewController ()

@property (nonatomic, strong) NSArray *tableData;

@end

@implementation JCMessageParticipantTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.searchBar becomeFirstResponder];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = nil;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark - Private -

-(id<JCPhoneNumberDataSource>)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self.tableData objectAtIndex:indexPath.row];
}

-(JCMessageGroup *)conversationGroupAtIndexPath:(NSIndexPath *)indexPath
{
    id<JCPhoneNumberDataSource> phoneNumber = [self objectAtIndexPath:indexPath];
    if ([phoneNumber isKindOfClass:[Extension class]]) {
        return [[JCMessageGroup alloc] initWithPhoneNumber:phoneNumber resourceId:((Extension *)phoneNumber).pbxId];
    }

    NSString *resourceId;
    NSSet *dids = self.userManager.pbx.dids;
    if (dids.count == 1) {
        resourceId = ((DID *)dids.allObjects.firstObject).jrn;
    }
    JCMessageGroup *messageGroup = [[JCMessageGroup alloc] initWithPhoneNumber:phoneNumber resourceId:resourceId];
    return messageGroup;
}

#pragma mark - Setters -

-(void)setTableData:(NSArray *)tableData {
    _tableData = tableData;
    
    [self.tableView reloadData];
    
    CGFloat tableHeight = [self.tableView contentSize].height;
    
    // @!^$#$ Apple! Seriously!
    if (![UIDevice iOS8]) {
        tableHeight = [self.tableView sizeThatFits:CGSizeMake(self.tableView.frame.size.width, FLT_MAX)].height;
    }
    
    self.tableViewHeightConstraint.constant = MIN(tableHeight, self.view.bounds.size.height);
    [self.view setNeedsUpdateConstraints];
}

#pragma mark UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableData.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<JCPhoneNumberDataSource> phoneNumber = [self objectAtIndexPath:indexPath];
    
    static NSString *unknownNumberCell = @"UnknownNumberCell";
    static NSString *searchResultsCell = @"SearchResultCell";
    
    NSString *identifier = searchResultsCell;
    if ([phoneNumber isKindOfClass:[JCUnknownNumber class]]) {
        identifier = unknownNumberCell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if ([phoneNumber isKindOfClass:[JCAddressBookNumber class]]) {
        cell.textLabel.text = phoneNumber.name;
        cell.detailTextLabel.text = phoneNumber.detailText;
    } else if ([phoneNumber isKindOfClass:[PhoneNumber class]]) {
        cell.textLabel.text = ((PhoneNumber *)phoneNumber).contact.name;
        cell.detailTextLabel.text = phoneNumber.detailText;
    }
    else {
        cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Send SMS to %@", @"Send SMS to new participant's phone number."), phoneNumber.detailText];
    }
    return cell;
}

#pragma mark UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    JCMessageGroup *messageGroup = [self conversationGroupAtIndexPath:indexPath];
    [self.delegate messageParticipantTableViewController:self didSelectConversationGroup:messageGroup];
    [self.view endEditing:YES];
}

#pragma mark UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSMutableArray *results = [NSMutableArray new];
    if (searchText.isNumeric && searchText.length > 0) {
        [results addObject:[JCUnknownNumber unknownNumberWithNumber:searchText]];
    }
    
    User *user = self.userManager.user;
    NSArray *phoneNumbers = [self.phoneBook phoneNumbersWithKeyword:searchText forUser:user forLine:nil sortedByKey:@"name" ascending:YES];
    [results addObjectsFromArray:phoneNumbers];
    self.tableData = results;
}

@end
