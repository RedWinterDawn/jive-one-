//
//  DID.h
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PBX, SMSMessage;

@interface DID : NSManagedObject

@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSString * didId;
@property (nonatomic, retain) PBX *pbx;
@property (nonatomic, retain) NSSet *smsMessages;
@end

@interface DID (CoreDataGeneratedAccessors)

- (void)addSmsMessagesObject:(SMSMessage *)value;
- (void)removeSmsMessagesObject:(SMSMessage *)value;
- (void)addSmsMessages:(NSSet *)values;
- (void)removeSmsMessages:(NSSet *)values;

@end
