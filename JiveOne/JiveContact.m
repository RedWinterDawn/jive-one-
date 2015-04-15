//
//  JiveContact.m
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JiveContact.h"
#import "Line.h"
#import "PBX.h"

@implementation JiveContact

@dynamic extension;
@dynamic jrn;
@dynamic pbxId;

#pragma mark - Transient Properties -

-(NSString *)number
{
    return self.extension;
}

-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    NSAttributedString *attributedString = [super detailTextWithKeyword:keyword font:font color:color];
    if (!attributedString) {
        return nil;
    }
    
    // Add the type to the front of the string, since all jive contacts have extensions
    NSMutableAttributedString *attributedNumberText = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           font, NSFontAttributeName,
                           color, NSForegroundColorAttributeName, nil];
    
    NSAttributedString *typeString = [[NSAttributedString alloc] initWithString:@"ext: " attributes:attrs];
    [attributedNumberText insertAttributedString:typeString atIndex:0];
    return attributedNumberText;
}

@end


@implementation JiveContact (Search)

+(JiveContact *)jiveContactWithExtension:(NSString *)number forLine:(Line *)line;
{
    static NSString *format = @"pbxId = %@ AND jrn != %@ AND extension = %@";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:format, line.pbx.pbxId, line.jrn, number];
    return [JiveContact MR_findFirstWithPredicate:predicate inContext:line.managedObjectContext];
}

@end