//
//  ContactGroup.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/9/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact;

@interface ContactGroup : NSManagedObject

@property (nonatomic, retain) NSString * groupId;
@property (nonatomic, retain) NSString * name;

@property (nonatomic, retain) NSSet *contacts;

@end

@interface ContactGroup (CoreDataGeneratedAccessors)

- (void)addContactsObject:(Contact *)value;
- (void)removeContactsObject:(Contact *)value;
- (void)addContacts:(NSSet *)values;
- (void)removeContacts:(NSSet *)values;

@end