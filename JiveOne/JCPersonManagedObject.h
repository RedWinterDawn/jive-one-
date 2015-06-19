//
//  Person.h
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonDataSource.h"

@import CoreData;
@import Foundation;

@interface JCPersonManagedObject : NSManagedObject <JCPersonDataSource>

// Attributes
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSString *t9;

@end
