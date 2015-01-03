//
//  Contact+Custom.h
//  JiveOne
//
//  Created by Robert Barclay on 12/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Contact.h"

@interface Contact (V5Client)

// Retrives all contacts for a line.
+ (void)downloadContactsForLine:(Line *)line complete:(CompletionHandler)completed;

@end


