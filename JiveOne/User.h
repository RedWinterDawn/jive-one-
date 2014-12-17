//
//  User.h
//  JiveOne
//
//  Created by Robert Barclay on 12/9/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PBX;

@interface User : NSManagedObject

// Attributes
@property (nonatomic, retain) NSString * jiveUserId;

// Relationships
@property (nonatomic, retain) NSSet *pbxs;

@end

@interface User (CoreDataGeneratedAccessors)

- (void)addPbxsObject:(PBX *)value;
- (void)removePbxsObject:(PBX *)value;
- (void)addPbxs:(NSSet *)values;
- (void)removePbxs:(NSSet *)values;

@end
