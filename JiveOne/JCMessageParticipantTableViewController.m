//
//  JCMessageParticipantViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 2/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMessageParticipantTableViewController.h"

#import "JCAddressBook.h"
#import "JCUnknownNumber.h"
#import "NSString+Additions.h"

@interface JCMessageParticipantTableViewController ()
{
    NSMutableArray *_participants;
    NSArray *_tableData;
}

@property (nonatomic, strong) NSArray *tableData;

@end

@implementation JCMessageParticipantTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableData = [NSMutableArray array];
}

-(void)setTableData:(NSArray *)tableData {
    _tableData = tableData;
    
    [self.tableView reloadData];
    
    CGFloat tableHeight = [self.tableView contentSize].height;
    
    // @!^$#$ Apple! Seriously!
    if (![UIDevice iOS8]) {
        tableHeight = [self.tableView sizeThatFits:CGSizeMake(self.tableView.frame.size.width, FLT_MAX)].height;
    }
    
    self.tableViewHeightConstraint.constant = tableHeight;
    [self.view setNeedsUpdateConstraints];
}

-(id<JCPerson>)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self.tableData objectAtIndex:indexPath.row];
}

#pragma mark - Delegate Handlers -

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
    id<JCPerson> person = [self objectAtIndexPath:indexPath];
    NSString *identifier;
    if ([person isKindOfClass:[JCUnknownNumber class]]) {
        identifier = @"UnknownNumberCell";
    } else {
        identifier = @"SearchResultCell";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    cell.textLabel.text = person.detailText;
    return cell;
}

#pragma mark UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<JCPerson> person = [self objectAtIndexPath:indexPath];
    [self.delegate messageParticipantTableViewController:self didSelectParticipants:@[person]];
}

#pragma mark UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSMutableArray *people = [NSMutableArray new];
    if (searchText.isNumeric && searchText.length > 0) {
        [people addObject:[JCUnknownNumber unknownNumberWithNumber:searchText]];
    }
    self.tableData = people;
}

@end
