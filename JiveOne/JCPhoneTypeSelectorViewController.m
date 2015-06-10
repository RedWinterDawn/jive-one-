//
//  JCPhoneTypeSelectorTableController.m
//  JiveOne
//
//  Created by P Leonard on 6/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneTypeSelectorViewController.h"

@interface JCPhoneTypeSelectorViewController (){
    NSArray *_phoneTypes;
}

@end

@implementation JCPhoneTypeSelectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _phoneTypes = @[NSLocalizedString(@"home", @"PhoneTypeSelector"),
                   NSLocalizedString(@"work", @"PhoneTypeSelector"),
                   NSLocalizedString(@"iPhone", @"PhoneTypeSelector"),
                   NSLocalizedString(@"mobile", @"PhoneTypeSelector"),
                   NSLocalizedString(@"main", @"PhoneTypeSelector"),
                   NSLocalizedString(@"home fax", @"PhoneTypeSelector"),
                   NSLocalizedString(@"work fax", @"PhoneTypeSelector"),
                   NSLocalizedString(@"pager", @"PhoneTypeSelector")];
    
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _phoneTypes.count ;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [_delegate phoneTypeSelectorController:self didSelectPhoneType:cell.textLabel.text];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = [_phoneTypes objectAtIndex:indexPath.row];
    
    return cell;
}

@end
