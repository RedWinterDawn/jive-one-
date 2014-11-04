//
//  Voicemail.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Voicemail.h"
#import "Lines.h"
#import "PBX.h"
#import "Common.h"

#import "NSManagedObject+JCCoreDataAdditions.h"

@implementation Voicemail

@dynamic jrn;
@dynamic mailboxUrl;
@dynamic url_changeStatus;
@dynamic url_download;
@dynamic url_pbx;
@dynamic url_self;
@dynamic voicemail;

#pragma mark - Setters -

-(void)setDuration:(NSInteger)duration
{
    [self setPrimitiveValueFromIntegerValue:duration forKey:@"duration"];
}

-(void)setMarkForDeletion:(BOOL)markForDeletion
{
    [self setPrimitiveValueFromBoolValue:markForDeletion forKey:@"markForDeletion"];
}

#pragma mark - Getters -

-(NSInteger)duration
{
    return [self integerValueFromPrimitiveValueForKey:@"duration"];
}

-(BOOL)markForDeletion
{
    return [self boolValueFromPrimitiveValueForKey:@"markForDeletion"];
}

-(NSString *)displayExtension
{
    NSString *extension = self.number;
    Lines *mailbox = [Lines MR_findFirstByAttribute:@"mailboxUrl" withValue:self.mailboxUrl];
    if (mailbox)
    {
        PBX *pbx = [PBX MR_findFirstByAttribute:@"pbxId" withValue:mailbox.pbxId];
        if (pbx) {
            if ([Common stringIsNilOrEmpty:pbx.name]) {
                extension = [NSString stringWithFormat:@"%@ on %@", mailbox.externsionNumber, pbx.name];
            }
            else {
                extension = [NSString stringWithFormat:@"%@", mailbox.externsionNumber];
            }
        }
        else {
            extension = [NSString stringWithFormat:@"%@", mailbox.externsionNumber];
        }
    }
    
    if ([Common stringIsNilOrEmpty:extension] || [extension isEqualToString:@"Unknown"]) {
        NSString *regexForNumber = @"<.+?>";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexForNumber options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *matches = [regex matchesInString:self.name options:0 range:NSMakeRange(0, [self.name length])];
        
        if (matches.count > 0) {
            NSString *callerNumber = [self.name substringWithRange:[matches[0] range]];
            callerNumber = [callerNumber stringByReplacingOccurrencesOfString:@"<" withString:@""];
            callerNumber = [callerNumber stringByReplacingOccurrencesOfString:@">" withString:@""];
            extension = callerNumber;
        }
    }
    return extension;
}

-(NSString *)displayDuration
{
    return  [NSString stringWithFormat:@"%ld:%02ld", self.duration / 60, self.duration % 60, nil];
}

@end
