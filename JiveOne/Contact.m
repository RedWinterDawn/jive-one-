//
//  Contact.m
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Contact.h"
#import "PBX.h"
#import "NSManagedObject+JCCoreDataAdditions.h"

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

-(NSString *)detailText
{
    NSString * detailText = super.detailText;
    if (self.pbx) {
        NSString *name = self.pbx.name;
        if (name && !name.isEmpty) {
            detailText = [NSString stringWithFormat:@"%@ on %@", self.extension, name];
        }
        else {
            detailText = [NSString stringWithFormat:@"%@", self.extension];
        }
    }
    return detailText;
}

@dynamic events;
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
