//
//  JCStaticSectionInfo.m
//  JiveOne
//
//  Created by Robert Barclay on 6/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCStaticSectionInfo.h"
#import "JCStaticRowData.h"

@interface JCStaticSectionInfo () {
    NSMutableArray *_objects;
}

@end

@implementation JCStaticSectionInfo

-(instancetype)init
{
    if (self = [super init]){
        _objects = [NSMutableArray new];
    }
    return self;
}

#pragma mark - Getters -

-(NSUInteger)numberOfObjects
{
    return _objects.count;
}

-(NSUInteger)visibleRows
{
    NSInteger count = 0;
    for (JCStaticRowData *row in _objects) {
        if (!row.isHidden) {
            ++count;
        }
    }
    return count;
}


#pragma mark - Methods -

-(void)addRow:(JCStaticRowData *)row
{
    if (![_objects containsObject:row]) {
        [_objects addObject:row];
    }
}

-(void)addRow:(JCStaticRowData *)row atIndexPath:(NSIndexPath *)indexPath
{
    if (![_objects containsObject:row] && _objects.count >= indexPath.row) {
        [_objects insertObject:row atIndex:indexPath.row];
    }
}

-(void)removeRow:(JCStaticRowData *)row
{
    [_objects removeObject:row];
}

/*
- (NSInteger)visibleRowIndexWithTableViewCell:(UITableViewCell *)cell {
    
    NSInteger i = 0;
    for (JCStaticRowData *row in _objects) {
        if (row.cell == cell) {
            return i;
        }
        
        if (!row.hidden) {
            ++i;
        }
    }
    return -1;
}
 */

@end
