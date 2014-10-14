//
//  OutgoingCall+Custom.m
//  JiveOne
//
//  Created by P Leonard on 10/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "OutgoingCall+Custom.h"

@implementation OutgoingCall (Custom)

+(void)addIncommingCallWithLineSession:(JCLineSession *)session
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        OutgoingCall *outgoingCall = [NSEntityDescription insertNewObjectForEntityForName:kOutgoingCallEntityName inManagedObjectContext:localContext];
        outgoingCall.timeStamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
        outgoingCall.name = session.callTitle;
        outgoingCall.number = session.callDetail;
        
    } completion:^(BOOL success, NSError *error) {
        //completed(success);
        //[self fetchVoicemailInBackground];
    }];
}

@end
