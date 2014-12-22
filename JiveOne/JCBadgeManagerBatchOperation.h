//
//  JCBadgeManagerBatchOperation.h
//  JiveOne
//
//  Created by Robert Barclay on 12/19/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

@interface JCBadgeManagerBatchOperation : NSOperation

-(instancetype)initWithDictionaryUpdate:(NSDictionary *)updateDictionary;

@property (nonatomic, readonly) NSMutableDictionary *badges;

@end
