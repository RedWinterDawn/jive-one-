//
//  JCV5ApiClient+Jasmine.h
//  JiveOne
//
//  Created by Robert Barclay on 7/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCV5ApiClient.h"

@interface JCV5ApiClient (Jasmine)

+ (void)requestPrioritySessionForJediId:(NSString *)deviceToken
                             completion:(JCApiClientCompletionHandler)completion;
@end
