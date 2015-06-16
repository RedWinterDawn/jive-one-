//
//  Contact+V5Client.h
//  JiveOne
//
//  Created by Robert Barclay on 6/15/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Contact.h"

@interface Contact (V5Client)

+ (void)downloadContactsForUser:(User *)user completion:(CompletionHandler)completion;

+ (void)downloadContact:(Contact *)contact completion:(CompletionHandler)completion;

+ (void)uploadContact:(Contact *)contact completion:(CompletionHandler)completion;

+ (void)deleteContact:(Contact *)contact completion:(CompletionHandler)completion;

@end
