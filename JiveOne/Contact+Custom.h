//
//  Contact+Custom.h
//  JiveOne
//
//  Created by Robert Barclay on 12/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Contact.h"
#import "JCV5ApiClient.h"

@interface Contact (Custom)

// Retrives all contacts for a line.
+ (void)downloadContactsForLine:(Line *)line complete:(CompletionHandler)completed;

@end
