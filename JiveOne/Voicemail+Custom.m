//
//  Voicemail+Custom.m
//  JiveOne
//
//  Created by Daniel George on 3/21/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Voicemail+Custom.h"
#import "Constants.h"

@implementation Voicemail (Custom)
  
+ (NSArray *)RetrieveVoicemailById:(NSString *)conversationId
{
    NSArray *conversations = [super MR_findByAttribute:@"conversationId" withValue:conversationId andOrderBy:@"lastModified" ascending:YES];
    return conversations;
}

#pragma mark - CRUD for Voicemail
+ (void)addVoicemails:(NSArray *)entryArray
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    for (NSDictionary *entry in entryArray) {
        if ([entry isKindOfClass:[NSDictionary class]]) {
            [self addVoicemail:entry withManagedContext:context];
        }
    }
}

+ (Voicemail *)addVoicemailEntry:(NSDictionary*)entry{
    return [self addVoicemail:entry withManagedContext:nil];
}

+ (Voicemail *)addVoicemail:(NSDictionary*)dictionary withManagedContext:(NSManagedObjectContext *)context
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    
    Voicemail *vmail;
    //find object in core data with same urn as voicemail entry in json
    NSArray *result = [Voicemail MR_findByAttribute:@"urn" withValue:dictionary[@"urn"]];
    
    // if there are results, we're updating, else we're creating
    if (result.count > 0) {
        vmail = result[0];
        [self updateVoicemail:vmail withDictionary:dictionary managedContext:context];
    }
    else {
        //create and save
        vmail = [Voicemail MR_createInContext:context];
        vmail.urn = dictionary[@"urn"];
        vmail.lastModified = [NSNumber numberWithLongLong:[dictionary[@"lastModified"] longLongValue]];
        vmail.callerId = dictionary[@"callerId"];
        vmail.createdDate = [NSNumber numberWithLongLong:[dictionary[@"createdDate"] longLongValue]];
        vmail.duration = [NSNumber numberWithInteger:[dictionary[@"length"] intValue]];
        // vmail.voicemail = [NSData dataWithContentsOfURL:[NSURL URLWithString:dictionary[@"file"]]];//fetch in background
        vmail.voicemailUrl = dictionary[@"file"];
        vmail.read = [NSNumber numberWithBool:[dictionary[@"read"] boolValue]];
        
        
        //Save conversation entry
        [context MR_saveToPersistentStoreAndWait];
    }
    return vmail;
}

+ (Voicemail *)updateVoicemail:(Voicemail*)vmail withDictionary:(NSDictionary*)dictionary managedContext:(NSManagedObjectContext *)context
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    // if last modified timestamps are the same, then there's no need to update anything.
    long lastModifiedFromEntity = [vmail.lastModified longLongValue];
    long lastModifiedFromDictionary = [dictionary[@"lastModified"] longLongValue];
    
    if (lastModifiedFromDictionary > lastModifiedFromEntity) {
        
        vmail.urn = dictionary[@"urn"];
        vmail.lastModified = [NSNumber numberWithLongLong:[dictionary[@"lastModified"] longLongValue]];
        vmail.callerId = dictionary[@"callerId"];
        vmail.createdDate = [NSNumber numberWithLongLong:[dictionary[@"createdDate"] longLongValue]];
        vmail.duration = [NSNumber numberWithInteger:[dictionary[@"length"] intValue]];
        vmail.voicemailUrl = dictionary[@"file"];
        vmail.read = [NSNumber numberWithBool:[dictionary[@"read"] boolValue]];

        
        //Save conversation dictionary
        [context MR_saveToPersistentStoreAndWait];
    }
    
    return vmail;
}
//
//+ (void)backgroundLoadVoicemailWithDictionary:(NSDictionary*)dictionary managedContext:(NSManagedObjectContext *)context
//{
//    
//    if (!context) {
//        context = [NSManagedObjectContext MR_contextForCurrentThread];
//    }
//
//    NSArray* entries = [dictionary objectForKey:@"entries"];
////    NSDictionary *voicemails = [(NSDictionary*)dictionary objectForKey:@"entries"];
//
//    
//    for (NSDictionary *vmail in entries){
//        //find voicemail in core data using predicate where vmail[urn] == voicemail.urn
//        Voicemail *aVoicemail = [Voicemail MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"urn == %@", vmail[@"urn"]] inContext:context][0];
//        
//        //if data is empty, do fetch vmail[file]
//        if(aVoicemail.message == nil ){
//            //TODO: preform fetch
//            
//            
//            //save voicemail back to core data
//            [context MR_saveToPersistentStoreAndWait];
//        }
//    }
//}

+ (void)fetchVoicemailInBackground
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"voicemail == nil"];
    
    dispatch_queue_t queue = dispatch_queue_create("load voicemails", NULL);
    dispatch_async(queue, ^{
        NSArray *voicemails = [Voicemail MR_findAllWithPredicate:pred inContext:context];
        for (Voicemail *vm in voicemails) {
            if ([kVoicemailURLOverRide  isEqual:@"YesUseAWSPlaceholderURL"]) {
                vm.voicemail = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://s3-us-west-2.amazonaws.com/jive-mobile/voicemail/userId/dleonard/TestVoicemail2.wav"]];
            }else{
                vm.voicemail = [NSData dataWithContentsOfURL:[NSURL URLWithString:vm.voicemailUrl]];
            }
        }
            [context MR_saveToPersistentStoreAndWait];
    });

}


@end
