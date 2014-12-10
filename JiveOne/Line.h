//
//  Lines.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RecentEvent;
@class LineConfiguration;
@class PBX;

@interface Line : NSManagedObject

// Attributes
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * externsionNumber;
@property (nonatomic, retain) id groups;
@property (nonatomic, retain) NSNumber * inUse;
@property (nonatomic, retain) NSNumber * isFavorite;
@property (nonatomic, retain) NSString * jrn;
@property (nonatomic, retain) NSString * lineId;
@property (nonatomic, retain) NSString * pbxId;
@property (nonatomic, retain) NSNumber * state;
@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) NSString * mailboxJrn;
@property (nonatomic, retain) NSString * mailboxUrl;

// Transient Attributes
@property (nonatomic, readonly) NSString *firstLetter;
@property (nonatomic, readonly) NSString *detailText;

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