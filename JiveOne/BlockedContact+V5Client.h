//
//  DID+V5Client.h
//  JiveOne
//
//  Created by Robert Barclay on 5/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "BlockedContact.h"

@interface BlockedContact (V5Client)

#pragma mark - Blocking -

+(void)downloadBlockedForDIDs:(NSSet *)dids completion:(CompletionHandler)completion;

+(void)downloadBlockedForDID:(DID *)did completion:(CompletionHandler)completion;

@end
