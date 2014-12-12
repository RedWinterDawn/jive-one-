//
//  Contact.h
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Person.h"

@class PBX;
@class ContactGroup;

@interface Contact : Person

// Attributes
@property (nonatomic, retain) NSString *jiveUserId;
@property (nonatomic, getter=isFavorite) BOOL favorite;

// Relationships
@property (nonatomic, retain) NSSet *groups;
@property (nonatomic, retain) PBX *pbx;

@end

@interface Contact (CoreDataGeneratedAccessors)

- (void)addGroupsObject:(ContactGroup *)value;
- (void)removeGroupsObject:(ContactGroup *)value;
- (void)addGroups:(NSSet *)values;
- (void)removeGroups:(NSSet *)values;

@end