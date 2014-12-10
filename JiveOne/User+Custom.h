//
//  User+Custom.h
//  JiveOne
//
//  Created by Robert Barclay on 12/9/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "User.h"

@interface User (Custom)

+ (User *)userForJiveUserId:(NSString *)string context:(NSManagedObjectContext *)context;

@end
