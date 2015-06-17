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
  return @[NSLocalizedString(@"Home", @"PhoneTypeSelector"),
           NSLocalizedString(@"Work", @"PhoneTypeSelector"),
           NSLocalizedString(@"iPhone", @"PhoneTypeSelector"),
           NSLocalizedString(@"Mobile", @"PhoneTypeSelector"),
           NSLocalizedString(@"Main", @"PhoneTypeSelector"),
           NSLocalizedString(@"Home fax", @"PhoneTypeSelector"),
           NSLocalizedString(@"Work fax", @"PhoneTypeSelector"),
           NSLocalizedString(@"Pager", @"PhoneTypeSelector")];
}

+(NSArray *)addressTypes
{
    return @[NSLocalizedString(@"Home", @"PhoneTypeSelector"),
             NSLocalizedString(@"Work", @"PhoneTypeSelector"),
             NSLocalizedString(@"Other", @"PhoneTypeSelector")];
}

+(NSArray *)otherTypes
{
    return @[NSLocalizedString(@"Job Title", @"PhoneTypeSelector"),
             NSLocalizedString(@"Department", @"PhoneTypeSelector")];
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
