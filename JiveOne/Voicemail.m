//
//  Voicemail.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Voicemail.h"
#import "Line.h"
#import "PBX.h"
#import "Common.h"

#import "NSManagedObject+Additions.h"

NSString *const kVoicemailDataAttributeKey = @"data";

@implementation Voicemail

@dynamic jrn;
@dynamic mailboxUrl;
@dynamic url_changeStatus;
@dynamic url_download;
@dynamic url_pbx;
@dynamic url_self;
@dynamic data;
@dynamic transcription;

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
    Line *line = self.line;
    if (line)
    {
        if (line.pbx) {
            if (!line.pbx.name.isEmpty) {
                extension = [NSString stringWithFormat:@"%@ on %@", line.number, line.pbx.name];
            }
            else {
                extension = line.number;
            }
        }
        else {
            extension = line.number;
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
    return  [NSString stringWithFormat:@"%ld:%02ld", (long)self.duration / 60, (long)self.duration % 60, nil];
}

@end
