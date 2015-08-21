//
//  JCPersonDataSource.h
//  JiveOne
//
//  This protocol defines the minimum data values requierd to represent, display and show a person
//  from any source.
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;
@import UIKit;

#import <JCPhoneModule/JCPhoneNumberDataSource.h>

@protocol JCPersonDataSource <JCPhoneNumberDataSource>

@property (nonatomic, readonly) NSString *firstNameFirstName;
@property (nonatomic, readonly) NSString *lastNameFirstName;

// Name Elements
@property (nonatomic, readonly) NSString *firstName;
@property (nonatomic, readonly) NSString *middleName;
@property (nonatomic, readonly) NSString *lastName;

// Initials
@property (nonatomic, readonly) NSString *firstInitial;
@property (nonatomic, readonly) NSString *middleInitial;
@property (nonatomic, readonly) NSString *lastInitial;
@property (nonatomic, readonly) NSString *initials;

@end
