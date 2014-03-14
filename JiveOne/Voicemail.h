//
//  Voicemail.h
//  JiveOne
//
//  Created by Doug Leonard on 3/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Voicemail : NSManagedObject

@property (nonatomic, retain) NSString * callerId;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * extension;
@property (nonatomic, retain) NSNumber * isRead;
@property (nonatomic, retain) NSData * message;
@property (nonatomic, retain) NSString * origdate;
@property (nonatomic, retain) NSString * urn;
@property (nonatomic, retain) NSData * voicemail;

@end
