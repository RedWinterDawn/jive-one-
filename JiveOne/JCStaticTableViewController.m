//
//  JCStaticTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 6/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCStaticTableViewController.h"

#import "JCStaticTableData.h"
#import "JCSwitchTableViewCell.h"

@interface JCStaticTableViewController () <JCStaticTableDataDelegate>
{
    JCStaticTableData *_tableData;
    BOOL _animated;
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

-(BOOL)cellIsHidden:(UITableViewCell *)cell
{
    return [_tableData cellIsHidden:cell];
}

-(void)reset
{
    if (_tableData) {
        [_tableData removeAddedCells];
        [_tableData setCells:_tableData.cells hidden:NO];
        [self setCells:_tableData.cells enabled:YES];
    }
}

-(void)startUpdates
{
    [_tableData beginUpdates];
}

-(void)endUpdates
{
    [_tableData endUpdates];
}

- (void)addCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [_tableData addCell:cell atIndexPath:indexPath];
}

- (void)removeCell:(UITableViewCell *)cell
{
    [_tableData removeCell:cell];
}

-(NSIndexPath *)indexPathForCell:(UITableViewCell *)cell
{
    if (_tableData) {
        return [_tableData indexPathForCell:cell];
    }
    return [self.tableView indexPathForCell:cell];
}

- (UITableViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath;
{
    if (_tableData) {
        return [_tableData cellForRowAtIndexPath:indexPath];
    }
    return [self.tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)heightForCell:(UITableViewCell *)cell
{
    return self.tableView.rowHeight;
}

- (void)setCells:(NSArray *)cells enabled:(BOOL)enabled;
{
    for (id object in cells) {
        if ([object isKindOfClass:[UITableViewCell class]]) {
            [self setCell:(UITableViewCell *)object enabled:enabled];
        }
    }
}

-(void)setCell:(UITableViewCell *)cell enabled:(BOOL)enabled
{
    if ([cell isKindOfClass:[JCSwitchTableViewCell class]]) {
        ((JCSwitchTableViewCell *)cell).enabled = enabled;
    }
    else {
        cell.userInteractionEnabled = enabled;
        cell.textLabel.enabled = enabled;
        cell.detailTextLabel.enabled = enabled;
    }
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
        return [_tableData numberOfRowsInSection:section];
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_tableData) {
        return [_tableData cellForRowAtIndexPath:indexPath];
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

-(NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_tableData) {
        return 0;
    }
    return [super tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_tableData) {
        UITableViewCell *cell = [self cellAtIndexPath:indexPath];
        return [self heightForCell:cell];
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat height = [super tableView:tableView heightForHeaderInSection:section];
    if (!_tableData) {
        return height;  // Return Original Section Header Height;
    }
    
    NSUInteger numberOfRows = [_tableData numberOfRowsInSection:section];
    if (numberOfRows != 0) {
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
    if (!_animated) {
        return;
    }
    [self.tableView beginUpdates];
}

- (void)tableData:(JCStaticTableData *)tableData
 didChangeSection:(JCStaticSectionInfo *)sectionInfo
          atIndex:(NSUInteger)sectionIndex
    forChangeType:(JCStaticTableDataChangeType)type
{
    if (!_animated) {
        return;
    }
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionIndex];
    switch(type)
    {
        case JCStaticTableDataInsert:
            [self.tableView insertSections:indexSet withRowAnimation:_animated ? _insertTableViewRowAnimation : UITableViewRowAnimationFade];
            break;
            
        case JCStaticTableDataDelete:
            [self.tableView deleteSections:indexSet withRowAnimation:_animated ? _deleteTableViewRowAnimation : UITableViewRowAnimationFade];
            break;
            
        default:
            break;
    }
}

- (void)tableData:(JCStaticTableData *)tableData
    didChangeCell:(UITableViewCell *)cell
      atIndexPath:(NSIndexPath *)indexPath
    forChangeType:(JCStaticTableDataChangeType)type
     newIndexPath:(NSIndexPath *)newIndexPath
{
    if (!_animated) {
        return;
    }
    
    UITableView *tableView = self.tableView;
    switch(type)
    {
        case JCStaticTableDataInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:_animated ? _insertTableViewRowAnimation : UITableViewRowAnimationFade];
            break;
            
        case JCStaticTableDataDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:_animated ? _deleteTableViewRowAnimation : UITableViewRowAnimationFade];
            break;
            
        case JCStaticTableDataUpdate:
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:_animated ? _reloadTableViewRowAnimation : UITableViewRowAnimationFade];
            break;
            
        case JCStaticTableDataMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:_animated ? _deleteTableViewRowAnimation : UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:_animated ? _insertTableViewRowAnimation : UITableViewRowAnimationFade];
            break;
    }
}

-(void)tableDataDidChangeContent:(JCStaticTableData *)tableData
{
    if (_animated) {
        [self.tableView endUpdates];
    }
    [self.tableView reloadData];
}

@end
