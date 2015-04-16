//
//  Contact.m
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Contact.h"
#import "PBX.h"
#import "NSManagedObject+Additions.h"

NSString *kContacktFavoriteAttribute = @"favorite";

@implementation Contact

@dynamic jiveUserId;

-(void)setFavorite:(BOOL)favorite
{
    [self setPrimitiveValueFromBoolValue:favorite forKey:kContacktFavoriteAttribute];
}

-(BOOL)isFavorite
{
    return [self boolValueFromPrimitiveValueForKey:kContacktFavoriteAttribute];
}

#pragma mark - Relationships

@dynamic lineEvents;
@dynamic conversations;
@dynamic pbx;
@dynamic groups;

@end

@implementation Contact (Search)

+ (Contact *)contactForExtension:(NSString *)extension pbx:(PBX *)pbx
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbx = %@ and extension = %@", pbx, extension];
    return [Contact MR_findFirstWithPredicate:predicate inContext:pbx.managedObjectContext];
}

@end
