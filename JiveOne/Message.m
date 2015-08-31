//
//  Message.m
//  JiveOne
//
//  Created by Robert Barclay on 1/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Message.h"

@implementation Message

@dynamic text;
@dynamic messageGroupId;
@dynamic resourceId;

-(NSString *)senderId
{
    return nil; // should be overwritten by subclass
}

-(NSString *)senderDisplayName
{
    return nil; // should be overwritten by subclass
}

-(BOOL)isMediaMessage
{
    return NO;
}

-(NSString *)detailText {
    return self.formattedLongDate;
}

+(NSPredicate *)predicateForMessagesWithGroupId:(NSString *)messageGroupId resourceId:(NSString *)resourceId pbxId:(NSString *)pbxId
{
    static NSString *predicateString = @"%K = %@ AND %K = %@ AND %K = %@ AND %K = %@";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString,
                              NSStringFromSelector(@selector(messageGroupId)), messageGroupId,
                              NSStringFromSelector(@selector(resourceId)), resourceId,
                              NSStringFromSelector(@selector(pbxId)), pbxId,
                              @"markForDeletion", @NO];
    return predicate;
}

@end
