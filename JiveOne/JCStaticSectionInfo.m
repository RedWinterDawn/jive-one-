//
//  JCStaticSectionInfo.m
//  JiveOne
//
//  Created by Robert Barclay on 6/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCStaticSectionInfo.h"
#import "JCStaticRowData.h"

@implementation JCStaticSectionInfo

@synthesize name = _name;
@synthesize indexTitle = _indexTitle;
@synthesize objects = _objects;

-(instancetype)initWithName:(NSString *)name;
{
    if (self = [super init]) {
        _name = name;
        _objects = [NSMutableArray new];
    }
    return self;
}

-(NSUInteger)numberOfObjects
{
    return _objects.count;
}

-(NSUInteger)visibleRows
{
    NSInteger count = 0;
    for (JCStaticRowData *row in _objects) {
        if (row.isHidden) {
            ++count;
        }
    }
    return count;
}

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

-(void)addRow:(JCStaticRowData *)row
{
    [_objects addObject:row];
}

-(void)removeRow:(JCStaticRowData *)row
{
    [_objects removeObject:row];
}

@end
