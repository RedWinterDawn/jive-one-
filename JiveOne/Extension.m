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
#import "NSManagedObject+Additions.h"

#define LINE_INDEX_OF_LINE_IN_JRN 5
// "jrn:line::jive:0144096e-bb05-ff06-702e-000100420002:0146db6f-52c9-9895-f67d-000100620002",

static NSString *kExtensionHiddenAttribute = @"hidden";

@implementation Extension

@dynamic jrn;
@dynamic pbxId;

-(void)setHidden:(BOOL)hidden
{
    [self setPrimitiveValueFromBoolValue:hidden forKey:kExtensionHiddenAttribute];
}

-(BOOL)hidden
{
    return [self boolValueFromPrimitiveValueForKey:kExtensionHiddenAttribute];
}

-(NSString *)type
{
    return @"ext";
}

-(NSString *)extensionId
{
    return [[self class] identifierFromJrn:self.jrn index:LINE_INDEX_OF_LINE_IN_JRN];
}

@end


@implementation Extension (Search)

+(Extension *)extensionForNumber:(NSString *)number onPbx:(PBX *)pbx excludingLine:(Line *)line
{
    static NSString *format = @"pbxId = %@ AND jrn != %@ AND number = %@";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:format, pbx.pbxId, line.jrn, number];
    return [Extension MR_findFirstWithPredicate:predicate inContext:pbx.managedObjectContext];
}

+(Extension *)extensionForNumber:(NSString *)number onPbx:(PBX *)pbx
{
    static NSString *format = @"pbxId = %@ AND number = %@";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:format, pbx.pbxId, number];
    return [Extension MR_findFirstWithPredicate:predicate inContext:pbx.managedObjectContext];
}

@end