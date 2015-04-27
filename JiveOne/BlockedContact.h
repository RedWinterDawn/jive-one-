//
//  BlockedContact.h
//  JiveOne
//
//  Created by Robert Barclay on 4/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumberManagedObject.h"

@class DID;

@interface BlockedContact : JCPhoneNumberManagedObject

@property (nonatomic, retain) DID *did;

@end
