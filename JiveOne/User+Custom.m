//
//  User+Custom.m
//  JiveOne
//
//  Created by Robert Barclay on 12/9/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "User+Custom.h"

@implementation User (Custom)

+ (User *)userForJiveUserId:(NSString *)jiveUserId context:(NSManagedObjectContext *)context
{
    // Try to find the user, if the user does not exist, truncate all the user data, and create a new user.
    User *user = [User MR_findFirstByAttribute:NSStringFromSelector(@selector(jiveUserId)) withValue:jiveUserId];
    if (!user) {
        [User MR_truncateAllInContext:context];
        user = [User MR_createInContext:context];
        user.jiveUserId = jiveUserId;
    }
    
    // Save Context if there are changes.
    if (user.managedObjectContext.hasChanges)
    {
        __autoreleasing NSError *error;
        if (![user.managedObjectContext save:&error]){
            NSLog(@"%@", [error description]);
        }
    }
    
    return user;
}

@end
