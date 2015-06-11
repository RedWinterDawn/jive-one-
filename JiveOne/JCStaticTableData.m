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
                [sectionInfo addRow:rowData];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                UITableViewCell *cell = [tableView.dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
                [_cells addObject:cell];
                rowData.cell = cell;
                
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

- (BOOL)cellIsHidden:(UITableViewCell *)cell
{
    JCStaticRowData *rowData = [self rowForCell:cell];
    return rowData.isHidden;
}

-(NSInteger)numberOfRowsInSection:(NSInteger)section
{
    JCStaticSectionInfo *sectionInfo = [_sections objectAtIndex:section];
    return sectionInfo.visibleRows;
}

- (UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    JCStaticRowData *rowData = [self visibleRowForIndexPath:indexPath];
    return rowData.cell;
}

- (NSIndexPath *)indexPathForCell:(UITableViewCell *)cell
{
    for (int section = 0; section < _sections.count; section++) {
        JCStaticSectionInfo *sectionInfo = [_sections objectAtIndex:section];
        NSArray *rows = sectionInfo.objects;
        for (int row = 0; row < rows.count; row++) {
            JCStaticRowData *rowData = [rows objectAtIndex:row];
            if (rowData.cell == cell) {
                return [NSIndexPath indexPathForRow:row inSection:section];
            }
        }
    }
    return nil;
}

- (NSIndexPath *)indexPathForVisibleIndexPath:(NSIndexPath *)indexPath
{
    JCStaticRowData *rowData = [self visibleRowForIndexPath:indexPath];
    return [self indexPathForRow:rowData];
}

- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JCStaticRowData *rowData = [self visibleRowForIndexPath:indexPath];
    CGFloat height = rowData.height;
    
    NSLog(@"%f", height);
    
    return height;
}

- (void)addCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [self beginUpdates];
    
    JCStaticSectionInfo *sectionInfo = [_sections objectAtIndex:indexPath.section];
    JCStaticRowData *row = [JCStaticRowData new];
    row.cell = cell;
    [sectionInfo addRow:row atIndexPath:indexPath];
    indexPath = [self indexPathForVisibleIndexPath:indexPath];
    [_delegate tableData:self didChangeCell:cell atIndexPath:nil forChangeType:JCStaticTableDataInsert newIndexPath:indexPath];
    [self endUpdates];
}

#pragma mark - Private -

- (JCStaticRowData *)visibleRowForIndexPath:(NSIndexPath *)indexPath
{
    JCStaticSectionInfo *sectionInfo = [_sections objectAtIndex:indexPath.section];
    NSUInteger visibleCount = -1;
    for (JCStaticRowData *rowData in sectionInfo.objects) {
        if (!rowData.isHidden) {
            ++visibleCount;
        }
        
        if (indexPath.row == visibleCount) {
            return rowData;
        }
    }
    return nil;
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
