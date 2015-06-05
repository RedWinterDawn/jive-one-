//
//  Contact.h
//  JiveOne
//
//  Created by Robert Barclay on 6/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "JCPersonManagedObject.h"

@class PhoneNumber;

@interface Contact : JCPersonManagedObject

// Attributes

@property (nonatomic, retain) NSString *etag;
@property (nonatomic, retain) NSString *data;

// Relationships

@property (nonatomic, retain) NSSet *phoneNumbers;

@end

@interface Contact (CoreDataGeneratedAccessors)

- (void)addPhoneNumbersObject:(PhoneNumber *)value;
- (void)removePhoneNumbersObject:(PhoneNumber *)value;
- (void)addPhoneNumbers:(NSSet *)values;
- (void)removePhoneNumbers:(NSSet *)values;

@end
