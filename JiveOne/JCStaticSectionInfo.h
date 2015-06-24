//
//  JCStaticSectionInfo.h
//  JiveOne
//
//  Created by Robert Barclay on 6/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

@class JCStaticRowData;

@interface JCStaticSectionInfo : NSObject 

@property (nonatomic, readonly) NSArray *objects;
@property (nonatomic, readonly) NSUInteger numberOfObjects;
@property (nonatomic, readonly) NSUInteger visibleRows;

-(void)addRow:(JCStaticRowData *)row;
-(void)addRow:(JCStaticRowData *)row atIndexPath:(NSIndexPath *)indexPath;

-(void)removeRow:(JCStaticRowData *)row;

@end
