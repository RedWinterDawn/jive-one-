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
@class RecentEvent;

@interface Contact : Person

// Attributes
@property (nonatomic, retain) NSString *jiveUserId;
@property (nonatomic, getter=isFavorite) BOOL favorite;

// Relationships
@property (nonatomic, strong) NSSet *events;
@property (nonatomic, retain) NSSet *groups;
@property (nonatomic, retain) PBX *pbx;

@end

@interface Contact (CoreDataGeneratedAccessors)

- (void)addGroupsObject:(ContactGroup *)value;
- (void)removeGroupsObject:(ContactGroup *)value;
- (void)addGroups:(NSSet *)values;
- (void)removeGroups:(NSSet *)values;

- (void)addEventsObject:(RecentEvent *)value;
- (void)removeEventsObject:(RecentEvent *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;

@end

@interface Contact (Custom)

+ (Contact *)contactForExtension:(NSString *)extension pbx:(PBX *)pbx;

@end