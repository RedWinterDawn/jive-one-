//
//  Person.h
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "JCPerson.h"

@interface Person : NSManagedObject <JCPerson>

// Attributes
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;

@end
