//
//  User.h
//  JiveOne
//
//  Created by Robert Barclay on 12/9/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PBX, Contact, ContactGroup;

@interface User : NSManagedObject

// Attributes
@property (nonatomic, retain) NSString *jiveUserId;

// Relationships
@property (nonatomic, retain) NSSet *pbxs;
@property (nonatomic, retain) NSSet *contacts;
@property (nonatomic, retain) NSSet *contactGroups;

@end

@interface User (CoreDataGeneratedAccessors)

- (void)addPbxsObject:(PBX *)value;
- (void)removePbxsObject:(PBX *)value;
- (void)addPbxs:(NSSet *)values;
- (void)removePbxs:(NSSet *)values;

- (void)addContactsObject:(Contact *)value;
- (void)removeContactsObject:(Contact *)value;
- (void)addContacts:(NSSet *)values;
- (void)removeContacts:(NSSet *)values;

- (void)addContactGroupsObject:(ContactGroup *)value;
- (void)removeContactGroupsObject:(ContactGroup *)value;
- (void)addContactGroups:(NSSet *)values;
- (void)removeContactGroups:(NSSet *)values;

@end
