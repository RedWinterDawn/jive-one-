//
//  RecentEvent.h
//  JiveOne
//
//  Created by P Leonard on 10/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class IncommingCall, MissedCall, OutGoingCall;

@interface RecentEvent : NSManagedObject

@property (nonatomic, retain) NSString * typeOfEvent;
@property (nonatomic, retain) NSString * callerName;
@property (nonatomic, retain) NSString * callerNumber;
@property (nonatomic, retain) NSString * callerExt;
@property (nonatomic, retain) NSSet *missedCall;
@property (nonatomic, retain) NSSet *outgoingCall;
@property (nonatomic, retain) NSSet *incomnigCall;
@end

@interface RecentEvent (CoreDataGeneratedAccessors)

- (void)addMissedCallObject:(MissedCall *)value;
- (void)removeMissedCallObject:(MissedCall *)value;
- (void)addMissedCall:(NSSet *)values;
- (void)removeMissedCall:(NSSet *)values;

- (void)addOutgoingCallObject:(OutGoingCall *)value;
- (void)removeOutgoingCallObject:(OutGoingCall *)value;
- (void)addOutgoingCall:(NSSet *)values;
- (void)removeOutgoingCall:(NSSet *)values;

- (void)addIncomnigCallObject:(IncommingCall *)value;
- (void)removeIncomnigCallObject:(IncommingCall *)value;
- (void)addIncomnigCall:(NSSet *)values;
- (void)removeIncomnigCall:(NSSet *)values;

@end
