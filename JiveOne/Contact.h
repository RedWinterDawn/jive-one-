//
//  Contact.h
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Person.h"

@class PBX;

@interface Contact : Person

// Attributes
@property (nonatomic, getter=isFavorite) BOOL favorite;

// Relationships
@property (nonatomic, retain) PBX *pbx;

@end
