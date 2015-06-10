//
//  JCStaticTableData.m
//  JiveOne
//
//  Created by Robert Barclay on 6/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCStaticTableData.h"

@interface JCStaticTableData ()
{
    NSMutableArray *_cells;
    NSMutableArray *_sections;
    
    BOOL _batchUpdates;
}

@end

@implementation JCStaticTableData

- (instancetype)initWithTableView:(UITableView *)tableView delegate:(id<JCStaticTableDataDelegate>)delegate
{
    if (self = [super init])
    {
        _delegate = delegate;
        
        NSInteger numberOfSections = [tableView numberOfSections];
        _sections = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
        _cells = [NSMutableArray new];
        
        for (NSInteger section = 0; section < numberOfSections; ++section)
        {
            JCStaticSectionInfo *sectionInfo = [JCStaticSectionInfo new];
            NSInteger numberOfRows = [tableView numberOfRowsInSection:section];
            for (NSInteger row = 0; row < numberOfRows; ++row)
            {
                JCStaticRowData *rowData = [JCStaticRowData new];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                UITableViewCell *cell = [tableView.dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
                [_cells addObject:cell];
                rowData.cell = cell;
                [sectionInfo addRow:rowData];
            }
            [_sections addObject:sectionInfo];
        }
    }
    return self;
}

- (void)beginUpdates
{
    if (!_batchUpdates) {
        [_delegate tableDataWillChangeContent:self];
        _batchUpdates = TRUE;
    }
}

- (void)endUpdates
{
    if (_batchUpdates) {
        _batchUpdates = FALSE;
        [_delegate tableDataDidChangeContent:self];
    }
}

- (void)setCell:(UITableViewCell *)cell hidden:(BOOL)hidden
{
    if (!_batchUpdates) {
        [_delegate tableDataWillChangeContent:self];
    }
    
    [self internal_setCell:cell hidden:hidden];
    
    if (!_batchUpdates) {
        [_delegate tableDataDidChangeContent:self];
    }
}

- (void)setCells:(NSArray *)cells hidden:(BOOL)hidden
{
    if (!_batchUpdates) {
        [_delegate tableDataWillChangeContent:self];
    }
    
    for (UITableViewCell *cell in cells) {
        [self internal_setCell:cell hidden:hidden];
    }
    
    if (!_batchUpdates) {
        [_delegate tableDataDidChangeContent:self];
    }
}

- (void)internal_setCell:(UITableViewCell *)cell hidden:(BOOL)hidden
{
    JCStaticRowData *row = [self rowForCell:cell];
    JCStaticTableDataChangeType type;
    NSIndexPath *indexPath = nil;
    NSIndexPath *newIndexPath = nil;
    if (row.isHidden != hidden) {
        row.hidden = hidden;
        if (hidden) {
            type = JCStaticTableDataDelete;
            indexPath = [self indexPathForRow:row];
        } else {
            type = JCStaticTableDataInsert;
            newIndexPath = [self indexPathForRow:row];
        }
    } else {
        indexPath = [self indexPathForRow:row];
        type = JCStaticTableDataUpdate;
    }
    
    [_delegate tableData:self
           didChangeCell:cell
             atIndexPath:indexPath
           forChangeType:type
            newIndexPath:newIndexPath];
}

- (JCStaticRowData *)visibleRowForIndexPath:(NSIndexPath *)indexPath
{
//    JCStaticRowData *row = [self rowForIndexPath:indexPath];
//    if(!row.isHidden) {
//        return row;
//    }
//    return nil;
    return nil;
}

#pragma mark - Private -

-(NSIndexPath *)indexPathForRow:(JCStaticRowData *)row
{
    for (int section = 0; section < _sections.count; section++) {
        JCStaticSectionInfo *sectionInfo = [_sections objectAtIndex:section];
        if ([sectionInfo.objects containsObject:row]) {
            return [NSIndexPath indexPathForRow:[sectionInfo.objects indexOfObject:row] inSection:section];
        }
    }
    return nil;
}


//- (JCStaticRowData *)rowForIndexPath:(NSIndexPath *)indexPath
//{
//    JCStaticSectionInfo *sectionInfo = [_sections objectAtIndex:indexPath.section];
//    if (!sectionInfo) {
//        return nil;
//    }
//    
//    return [sectionInfo.objects objectAtIndex:indexPath.row];
//}
//
//
//

//
//-(NSIndexPath *)indexPathForVisibleRow:(JCStaticRowData *)row
//{
//    
//}


- (JCStaticRowData *)rowForCell:(UITableViewCell *)cell
{
    for (JCStaticSectionInfo *sectionInfo in _sections) {
        NSArray *objects = sectionInfo.objects;
        for (JCStaticRowData *row in objects) {
            if (row.cell == cell) {
                return row;
            }
        }
    }
    return nil;
}

//- (NSIndexPath *)indexPathForInsertingOriginalRow:(JCStaticRowData *)row {
//    
//    NSInteger section = row.originalIndexPath.section;
//    JCStaticSectionInfo *sectionInfo = [_sections objectAtIndex:section];
//    NSInteger index = -1;
//    for (NSInteger i = 0; i < row.originalIndexPath.row; ++i) {
//        
//        JCStaticRowData * oRow = [sectionInfo.objects objectAtIndex:i];
//        if (!oRow.hidden) {
//            ++index;
//        }
//    }
//    return [NSIndexPath indexPathForRow:index + 1 inSection:section];
//}
//
//- (NSIndexPath *)indexPathForDeletingOriginalRow:(JCStaticRowData *)row {
//    
//    NSInteger section = row.originalIndexPath.section;
//    JCStaticSectionInfo *sectionInfo = [_sections objectAtIndex:section];
//    NSInteger index = -1;
//    for (NSInteger i = 0; i < row.originalIndexPath.row; ++i) {
//        
//        JCStaticRowData *oRow = [sectionInfo.objects objectAtIndex:i];
//        if (!oRow.hiddenReal) {
//            ++index;
//        }
//    }
//    return [NSIndexPath indexPathForRow:index + 1 inSection:section];
//}

//- (void)prepareUpdates {
//    
//    [_insertIndexPaths removeAllObjects];
//    [_deleteIndexPaths removeAllObjects];
//    [_updateIndexPaths removeAllObjects];
//    
//    for (JCStaticSectionInfo *sectionInfo in _sections)
//    {
//        for (JCStaticRowData *row in sectionInfo.objects)
//        {
//            switch (row.batchOperation) {
//                case kBatchOperationDelete:
//                    [_deleteIndexPaths addObject:[self indexPathForDeletingOriginalRow:row]];
//                    break;
//                    
//                case kBatchOperationInsert:
//                    [_insertIndexPaths addObject:[self indexPathForInsertingOriginalRow:row]];
//                    break;
//                    
//                default:
//                    [_updateIndexPaths addObject:[self indexPathForInsertingOriginalRow:row]];
//                    break;
//            }
//        }
//        
//    }
//    
//    for (JCStaticSectionInfo * sectionInfo in _sections) {
//        for (JCStaticRowData * row in sectionInfo.objects) {
//            row.hiddenReal = row.hiddenPlanned;
//            row.batchOperation = kBatchOperationNone;
//        }
//    }
//}

@end
