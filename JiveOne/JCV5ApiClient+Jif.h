//
//  JCV5ApiClient+Jif.h
//  JiveOne
//
//  Created by Robert Barclay on 7/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCV5ApiClient.h"

@class User;

@interface JCV5ApiClient (Jif)

+ (void)requestPBXInforForUser:(User *)user
                     competion:(JCApiClientCompletionHandler)completion;

@end
