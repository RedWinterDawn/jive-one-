//
//  JCStaticTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 6/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCStaticTableViewController.h"

#import "JCStaticTableData.h"

@interface JCStaticTableViewController () <JCStaticTableDataDelegate>
{
    JCStaticTableData *_tableData;
}

@end

@implementation JCStaticTableViewController

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        _insertTableViewRowAnimation = UITableViewRowAnimationRight;
        _deleteTableViewRowAnimation = UITableViewRowAnimationLeft;
        _reloadTableViewRowAnimation = UITableViewRowAnimationMiddle;
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableData = [[JCStaticTableData alloc] initWithTableView:self.tableView delegate:self];
}

#pragma mark - Methods -

-(void)setCell:(UITableViewCell *)cell hidden:(BOOL)hidden
{
    [_tableData setCell:cell hidden:hidden];
}

-(void)setCells:(NSArray *)cells hidden:(BOOL)hidden
{
    [_tableData setCells:cells hidden:hidden];
}

-(void)startUpdates
{
    [_tableData beginUpdates];
}

-(void)endUpdates
{
    [_tableData endUpdates];
}

#pragma mark - Delegate Handelers -

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_tableData) {
        return _tableData.sections.count;
    }
    return [super numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_tableData) {
        JCStaticSectionInfo *sectionInfo = [_tableData.sections objectAtIndex:section];
        return sectionInfo.visibleRows;
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_tableData) {
        JCStaticRowData *row = [_tableData visibleRowForIndexPath:indexPath];
        return row.cell;
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_tableData != nil) {
        JCStaticRowData *row = [_tableData visibleRowForIndexPath:indexPath];
        indexPath = [_tableData indexPathForRow:row];
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    CGFloat height = [super tableView:tableView heightForHeaderInSection:section];
    if (!_tableData) {
        return height;  // Return Original Section Header Height;
    }
    
    JCStaticSectionInfo *sectionInfo = [_tableData.sections objectAtIndex:section];
    if (sectionInfo.visibleRows != 0) {
        return height;
    }
    return CGFLOAT_MIN;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([tableView.dataSource tableView:tableView numberOfRowsInSection:section] == 0) {
        return nil;
    } else {
        return [super tableView:tableView titleForHeaderInSection:section];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = [super tableView:tableView heightForFooterInSection:section];
    if (!_tableData) {
        return height;  // Return Original Section Footer Height;
    }
    
    JCStaticSectionInfo *sectionInfo = [_tableData.sections objectAtIndex:section];
    if (sectionInfo.visibleRows != 0) {
        return height;
    }
    return CGFLOAT_MIN;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if ([tableView.dataSource tableView:tableView numberOfRowsInSection:section] == 0) {
        return nil;
    } else {
        return [super tableView:tableView titleForFooterInSection:section];
    }
}

#pragma mark JCStaticTableDataDelegate

-(void)tableDataWillChangeContent:(JCStaticTableData *)tableData
{
    [self.tableView beginUpdates];
}

- (void)tableData:(JCStaticTableData *)tableData
 didChangeSection:(JCStaticSectionInfo *)sectionInfo
          atIndex:(NSUInteger)sectionIndex
    forChangeType:(JCStaticTableDataChangeType)type
{
    
}

- (void)tableData:(JCStaticTableData *)tableData
    didChangeCell:(UITableViewCell *)cell
      atIndexPath:(NSIndexPath *)indexPath
    forChangeType:(JCStaticTableDataChangeType)type
     newIndexPath:(NSIndexPath *)newIndexPath
{
    
}

-(void)tableDataDidChangeContent:(JCStaticTableData *)tableData
{
    [self.tableView endUpdates];
}

@end
