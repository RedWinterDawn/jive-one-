//
//  Person.h
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Person : NSManagedObject

// Attributes
@property (nonatomic, retain) NSString * jrn;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * extension;
@property (nonatomic, retain) NSString * pbxId;

// Transient Attributes
@property (nonatomic, readonly) NSString *firstLetter;
@property (nonatomic, readonly) NSString *detailText;

@end
