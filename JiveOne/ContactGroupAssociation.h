//
//  ContactGroupAssociation.h
//  JiveOne
//
//  Created by Robert Barclay on 6/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact, ContactGroup;

@interface ContactGroupAssociation : NSManagedObject

// Attributes
@property (nonatomic, getter=isMarkedForDeletion) BOOL markForDeletion;
@property (nonatomic, getter=isMarkedForUpdate) BOOL markForUpdate;

// Relationships
@property (nonatomic, retain) ContactGroup *group;
@property (nonatomic, retain) Contact *contact;

@end
