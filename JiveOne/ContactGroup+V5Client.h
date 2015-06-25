//
//  ContactGroup+V5Client.h
//  JiveOne
//
//  Created by Robert Barclay on 6/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "ContactGroup.h"

@class Contact;

@interface ContactGroup (V5Client)

// Returns the data structure expected by the Server for POST or PUT operations when converted to JSON
@property (nonatomic, readonly) NSDictionary *serializedData;



@end
