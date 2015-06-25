//
//  ContactGroup.h
//  JiveOne
//
//  Created by Robert Barclay on 6/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Group.h"

@class ContactGroupAssociation, User;

@interface ContactGroup : Group

// Attributes
@property (nonatomic, getter=isMarkedForUpdate) BOOL markForUpdate;
@property (nonatomic, getter=isMarkedForDeletion) BOOL markForDeletion;
@property (nonatomic) NSInteger etag;

// Relationships
@property (nonatomic, retain) NSSet *contacts;
@property (nonatomic, strong) User *user;

@end


@interface ContactGroup (CoreDataGeneratedAccessors)

- (void)addContactsObject:(ContactGroupAssociation *)value;
- (void)removeContactsObject:(ContactGroupAssociation *)value;
- (void)addContacts:(NSSet *)values;
- (void)removeContacts:(NSSet *)values;

@end