//
//  VoicemailTranscription.h
//  JiveOne
//
//  Created by P Leonard on 5/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Voicemail;

@interface VoicemailTranscription : NSManagedObject

@property (nonatomic, retain) NSString * url_self;
@property (nonatomic, retain) NSString * text;
@property (nonatomic) float confidence;
@property (nonatomic) NSInteger wordCount;

// Relationship
@property (nonatomic, retain) Voicemail *voicemail;

@end
