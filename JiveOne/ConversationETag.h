//
//  ConversationETag.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/28/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ConversationETag : NSManagedObject

@property (nonatomic, retain) NSNumber * etag;

@end
