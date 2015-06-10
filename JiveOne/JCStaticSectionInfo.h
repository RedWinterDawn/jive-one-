//
//  JCStaticSectionInfo.h
//  JiveOne
//
//  Created by Robert Barclay on 6/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;
@class JCStaticRowData;

@interface JCStaticSectionInfo : NSObject <NSFetchedResultsSectionInfo> {
    NSMutableArray *_objects;
}

@property (nonatomic) NSUInteger visibleRows;

-(void)addRow:(JCStaticRowData *)row;
-(void)removeRow:(JCStaticRowData *)row;

@end
