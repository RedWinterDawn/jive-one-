//
//  BlockedContact.h
//  JiveOne
//
//  Created by Robert Barclay on 4/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "JCPhoneNumberManagedObject.h"

@class DID;

@interface BlockedContact : JCPhoneNumberManagedObject

@property (nonatomic, retain) DID *did;

@end
