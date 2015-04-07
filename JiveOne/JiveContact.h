//
//  JiveContact.h
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Person.h"

@interface JiveContact : Person

@property (nonatomic, retain) NSString * extension;
@property (nonatomic, retain) NSString * jrn;

// Transient
@property (nonatomic, retain) NSString * pbxId;

@end
