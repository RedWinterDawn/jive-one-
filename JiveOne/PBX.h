//
//  PBX.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact;
@class User;
@class Line;
@class DID;

@interface PBX : NSManagedObject

// Attributes
@property (nonatomic, retain) NSString * jrn;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, getter=isV5) BOOL v5;

// Relationships
@property (nonatomic, retain) NSSet * contacts;
@property (nonatomic, retain) User * user;
@property (nonatomic, retain) NSSet * lines;
@property (nonatomic, retain) NSSet * dids;

// Transient (Readonly)
@property (nonatomic, readonly) BOOL smsEnabled;
@property (nonatomic, readonly) NSString * displayName;
@property (nonatomic, readonly) NSString * pbxId;

@end

@interface PBX (CoreDataGeneratedAccessors)

- (void)addContactsObject:(Contact *)value;
- (void)removeContactsObject:(Contact *)value;
- (void)addContacts:(NSSet *)values;
- (void)removeContacts:(NSSet *)values;

- (void)addLinesObject:(Line *)value;
- (void)removeLinesObject:(Line *)value;
- (void)addLines:(NSSet *)values;
- (void)removeLines:(NSSet *)values;

- (void)addDidsObject:(DID *)value;
- (void)removeDidsObject:(DID *)value;
- (void)addDids:(NSSet *)values;
- (void)removeDids:(NSSet *)values;

@end