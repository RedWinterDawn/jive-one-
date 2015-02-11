//
//  JCPerson.h
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JCPerson <NSObject>

// Name Elements
@property (nonatomic, readonly) NSString *firstName;
@property (nonatomic, readonly) NSString *middleName;
@property (nonatomic, readonly) NSString *lastName;

// Name Composites
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *firstNameFirstName;
@property (nonatomic, readonly) NSString *lastNameFirstName;

// Name Initials
@property (nonatomic, readonly) NSString *firstInitial;
@property (nonatomic, readonly) NSString *middleInitial;
@property (nonatomic, readonly) NSString *lastInitial;
@property (nonatomic, readonly) NSString *initials;

@end
