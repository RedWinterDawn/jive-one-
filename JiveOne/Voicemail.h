//
//  Voicemail.h
//  JiveOne
//
//  Created by Daniel George on 3/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Voicemail : NSManagedObject

@property (nonatomic, retain) NSString * callerId;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * extension;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSData * message;
@property (nonatomic, retain) NSString * createdDate;
@property (nonatomic, retain) NSString * urn;
@property (nonatomic, retain) NSData * voicemail;
@property (nonatomic, retain) NSString * file;

@end
