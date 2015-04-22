//
//  Person.h
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonDataSource.h"
#import "JCPhoneNumberManagedObject.h"

@interface JCPersonManagedObject : JCPhoneNumberManagedObject <JCPersonDataSource>

// Attributes
@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;

@end
