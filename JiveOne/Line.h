//
//  Lines.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JiveContact.h"
#import "JCSipManagerProvisioningDataSource.h"

@class RecentEvent;
@class LineConfiguration;
@class PBX;

@interface Line : JiveContact <JCSipManagerProvisioningDataSource>

// Attributes
@property (nonatomic, retain) NSString * mailboxJrn;
@property (nonatomic, retain) NSString * mailboxUrl;
@property (nonatomic, getter=isActive) BOOL active;

// Transient Properties
@property (nonatomic, readonly) NSString * lineId;

// Relationships
@property (nonatomic, retain) NSSet *events;
@property (nonatomic, retain) LineConfiguration *lineConfiguration;
@property (nonatomic, retain) PBX *pbx;

@end

@interface Line (CoreDataGeneratedAccessors)

- (void)addEventsObject:(Line *)value;
- (void)removeEventsObject:(Line *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;

@end