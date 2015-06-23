//
//  JCPersonGroup.h
//  JiveOne
//
//  Created by Robert Barclay on 6/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

@protocol JCGroupDataSource <NSObject>

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *groupId;
@property (nonatomic, readonly) NSSet *members;

@property (nonatomic, readonly) NSString *sectionName;

@end
