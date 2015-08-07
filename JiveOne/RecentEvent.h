//
//  RecentEvent.h
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface RecentEvent : NSManagedObject

// Attributes
@property (nonatomic, strong) NSDate *date;        // The date of the event.
@property (nonatomic, getter=isRead) BOOL read;    // Indicates whether the event has been read.
@property (nonatomic, getter=isMarkedForDeletion) BOOL markForDeletion;
@property (nonatomic, strong) NSString *eventId;
@property (nonatomic, strong) NSString *pbxId;

// Transient Attributes.
@property (nonatomic, weak) NSNumber *timestamp;
@property (nonatomic, readonly) NSString *formattedModifiedShortDate;
@property (nonatomic, readonly) NSString *formattedLongDate;
@property (nonatomic) long long unixTimestamp;
@property (nonatomic, readonly) NSString *detailText;

// Marks the voicemail for deletion. Attempts to notify server of deletion.
- (void)markForDeletion:(CompletionHandler)completion;
- (void)markAsRead:(CompletionHandler)completion;

@end
