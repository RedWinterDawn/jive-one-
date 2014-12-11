//
//  PBX.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;
@class Line;

@interface PBX : NSManagedObject

// Attributes
@property (nonatomic, retain) NSString * jrn;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * pbxId;
@property (nonatomic, retain) NSString * selfUrl;
@property (nonatomic, getter=isV5) BOOL v5;

@property (nonatomic, readonly) NSString * displayName;

// Relationships
@property (nonatomic, retain) User * user;
@property (nonatomic, retain) NSSet * lines;

@end

@interface PBX (CoreDataGeneratedAccessors)

- (void)addLinesObject:(Line *)value;
- (void)removeLinesObject:(Line *)value;
- (void)addLines:(NSSet *)values;
- (void)removeLines:(NSSet *)values;

@end