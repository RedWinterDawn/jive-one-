//
//  JCPhoneTypeSelectorTableController.m
//  JiveOne
//
//  Created by P Leonard on 6/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCTypeSelectorViewController.h"

@interface JCTypeSelectorViewController (){
    NSArray *_phoneTypes;
}

@end

@implementation JCTypeSelectorViewController

+(NSArray *)phoneTypes
{
  return @[NSLocalizedString(@"home", @"PhoneTypeSelector"),
           NSLocalizedString(@"work", @"PhoneTypeSelector"),
           NSLocalizedString(@"iPhone", @"PhoneTypeSelector"),
           NSLocalizedString(@"mobile", @"PhoneTypeSelector"),
           NSLocalizedString(@"main", @"PhoneTypeSelector"),
           NSLocalizedString(@"home fax", @"PhoneTypeSelector"),
           NSLocalizedString(@"work fax", @"PhoneTypeSelector"),
           NSLocalizedString(@"pager", @"PhoneTypeSelector")];
}

+(NSArray *)addressTypes
{
    return @[NSLocalizedString(@"home", @"PhoneTypeSelector"),
             NSLocalizedString(@"work", @"PhoneTypeSelector"),
             NSLocalizedString(@"other", @"PhoneTypeSelector")];
}

+(NSArray *)otherTypes
{
    return @[NSLocalizedString(@"job title", @"PhoneTypeSelector"),
             NSLocalizedString(@"department", @"PhoneTypeSelector")];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _types.count ;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [_delegate typeSelectorController:self didSelectPhoneType:cell.textLabel.text];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = [_types objectAtIndex:indexPath.row];
    return cell;
}

@end
