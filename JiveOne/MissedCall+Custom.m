//
//  MissedCall+Custom.m
//  JiveOne
//
//  Created by P Leonard on 10/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "MissedCall+Custom.h"

@implementation MissedCall (Custom)

+(void)addMissedCallWithLineSession:(JCLineSession *)session
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        MissedCall *missedCall = [NSEntityDescription insertNewObjectForEntityForName:kMissedCallEntityName inManagedObjectContext:localContext];
        missedCall.timeStamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
        missedCall.name = session.callTitle;
        missedCall.number = session.callDetail;
        
    } completion:^(BOOL success, NSError *error) {
        //completed(success);
        //[self fetchVoicemailInBackground];
    }];
}


@end
