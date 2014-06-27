//
//  Mailbox.h
//  JiveOne
//
//  Created by Daniel George on 6/26/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Mailbox : NSManagedObject

@property (nonatomic, retain) NSString * extensionName;
@property (nonatomic, retain) NSString * extensionNumber;
@property (nonatomic, retain) NSString * jrn;
@property (nonatomic, retain) NSString * url_self_mailbox;

@end
