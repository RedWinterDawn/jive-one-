//
//  ContactInfo.h
//  JiveOne
//
//  Created by Robert Barclay on 6/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact;

@interface ContactInfo : NSManagedObject

@property (nonatomic) NSInteger order;
@property (nonatomic, retain) NSString * dataHash;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSString * value;

@property (nonatomic, retain) Contact *contact;

@end
