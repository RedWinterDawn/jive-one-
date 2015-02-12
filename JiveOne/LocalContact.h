//
//  LocalContact.h
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Person.h"

@class SMSMessage;

@interface LocalContact : Person

@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSNumber * personId;
@property (nonatomic, retain) NSSet *smsMessages;
@end

@interface LocalContact (CoreDataGeneratedAccessors)

- (void)addSmsMessagesObject:(SMSMessage *)value;
- (void)removeSmsMessagesObject:(SMSMessage *)value;
- (void)addSmsMessages:(NSSet *)values;
- (void)removeSmsMessages:(NSSet *)values;

@end
