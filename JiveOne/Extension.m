//
//  JiveContact.m
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Extension.h"
#import "Line.h"
#import "PBX.h"

@implementation Extension

@dynamic jrn;
@dynamic pbxId;

-(NSString *)detailText
{
    return [NSString stringWithFormat:@"ext: %@", super.detailText];
}

@end


@implementation Extension (Search)

+(Extension *)jiveContactWithExtension:(NSString *)number forLine:(Line *)line;
{
    static NSString *format = @"pbxId = %@ AND jrn != %@ AND extension = %@";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:format, line.pbx.pbxId, line.jrn, number];
    return [Extension MR_findFirstWithPredicate:predicate inContext:line.managedObjectContext];
}

@end