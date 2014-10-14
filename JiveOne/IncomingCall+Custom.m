//
//  IncomingCall+Custom.m
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "IncomingCall+Custom.h"
#import <MagicalRecord/MagicalRecord.h>

@implementation IncomingCall (Custom)

+(void)addIncommingCallWithLineSession:(JCLineSession *)session
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        IncomingCall *incomingCall = [NSEntityDescription insertNewObjectForEntityForName:kIncomingCallEntityName inManagedObjectContext:localContext];
        incomingCall.date = [NSDate date];
        incomingCall.name = session.callTitle;
        incomingCall.number = session.callDetail;
        
    } completion:^(BOOL success, NSError *error) {
        //completed(success);
        //[self fetchVoicemailInBackground];
    }];
}


@end
