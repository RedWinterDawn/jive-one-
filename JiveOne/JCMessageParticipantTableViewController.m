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
#import "JCConversationGroupObject.h"
#import "JCSMSConversationGroup.h"
#import "Extension.h"
#import "PBX.h"

@interface JCMessageParticipantTableViewController ()

@property (nonatomic, strong) NSArray *tableData;

@end

@implementation JCMessageParticipantTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableData = [NSMutableArray array];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(animateResizeWithNotification:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(animateResizeWithNotification:) name:UIKeyboardWillHideNotification object:nil];
    [self.searchBar becomeFirstResponder];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private -

-(id<JCPhoneNumberDataSource>)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self.tableData objectAtIndex:indexPath.row];
}

-(id<JCConversationGroupObject>)conversationGroupAtIndexPath:(NSIndexPath *)indexPath
{
    id<JCPhoneNumberDataSource> phoneNumber = [self objectAtIndexPath:indexPath];
    if ([phoneNumber isKindOfClass:[Extension class]]) {
        return nil; // TODO for chat.
    }
    return [[JCSMSConversationGroup alloc] initWithPhoneNumber:phoneNumber];
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

#pragma mark - Delegate Handlers -

-(void)animateResizeWithNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    CGRect kbframe = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    kbframe = [self.view convertRect:kbframe fromView:nil];
    
    CGRect frame = self.view.frame;
    frame.size.height = self.view.frame.size.height - kbframe.size.height - 44;
    
    NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateKeyframesWithDuration:duration
                                   delay:0
                                 options:(UIViewAnimationOptions)animationCurve << 16
                              animations:^{
                                  self.view.frame = frame;
                              }
                              completion:^(BOOL finished) {
                                  
                              }];
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
    NSString *identifier;
    if ([phoneNumber isKindOfClass:[JCUnknownNumber class]]) {
        identifier = @"UnknownNumberCell";
    } else {
        identifier = @"SearchResultCell";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if ([phoneNumber isKindOfClass:[JCAddressBookNumber class]]) {
        cell.textLabel.text = phoneNumber.name;
        cell.detailTextLabel.text = phoneNumber.detailText;
    } else {
        cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Send SMS to %@", @"Send SMS to new participant's phone number."), phoneNumber.detailText];
    }
    return cell;
}

#pragma mark UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<JCConversationGroupObject> conversationGroup = [self conversationGroupAtIndexPath:indexPath];
    [self.delegate messageParticipantTableViewController:self didSelectConversationGroup:conversationGroup];
    [self.view endEditing:YES];
}

#pragma mark UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSMutableArray *results = [NSMutableArray new];
    if (searchText.isNumeric && searchText.length > 0) {
        [results addObject:[JCUnknownNumber unknownNumberWithNumber:searchText]];
    }
    
    NSArray *phoneNumbers = [self.phoneBook phoneNumbersWithKeyword:searchText forLine:nil sortedByKey:@"name" ascending:YES];
    [results addObjectsFromArray:phoneNumbers];
    self.tableData = results;
}

@end
