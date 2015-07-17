//
//  JCV5ApiClient+Jedi.h
//  JiveOne
//
//  Created by Robert Barclay on 7/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCV5ApiClient.h"

@interface JCV5ApiClient (Jedi)

+ (void)requestJediIdForDeviceToken:(NSString *)deviceToken
                         completion:(JCApiClientCompletionHandler)completion;

+ (void)updateJediFromOldDeviceToken:(NSString *)oldDeviceToken
                    toNewDeviceToken:(NSString *)newDeviceToken
                          completion:(JCApiClientCompletionHandler)completion;

@end
