//
//  PersonEntities+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/18/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "PersonEntities+Custom.h"
#import "PersonMeta.h"

@implementation PersonEntities (Custom)

static NSManagedObjectContext *_context;

+ (void)addEntities:(NSArray *)entities me:(NSString *)me
{
    for (NSDictionary *entity in entities) {
        if ([entity isKindOfClass:[NSDictionary class]]) {
            [self addEntity:entity me:me withManagedContext:nil];
        }
    }
}

+ (PersonEntities *)addEntity:(NSDictionary*)entity me:(NSString *)me
{
    return [self addEntity:entity me:me withManagedContext:nil];
}

+ (PersonEntities *)addEntity:(NSDictionary*)entity me:(NSString *)me withManagedContext:(NSManagedObjectContext *)context
{
    if (context) {
        _context = context;
    }
    else {
        _context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    PersonEntities *c_ent = nil;
    @try {
        
        NSString *entityId = entity[@"id"];
        NSArray *result = [PersonEntities MR_findByAttribute:@"entityId" withValue:entityId];
        
        if (result.count > 0) {
            c_ent = result[0];
            return [self updateEntities:c_ent withDictionary:entity withManagedContext:_context];
        }
        else {
            c_ent = [PersonEntities MR_createInContext:_context];
            c_ent.lastModified = [entity objectForKey:@"lastModified"];
            c_ent.externalId = [entity objectForKey:@"externalId"];
            c_ent.presence = [entity objectForKey:@"presence"];
            c_ent.resourceGroupName = [entity objectForKey:@"company"];
            c_ent.tags = [entity objectForKey:@"tags"];
            c_ent.location = [entity objectForKey:@"location"];
            c_ent.firstName = [[entity objectForKey:@"name"] objectForKey:@"first"];
            c_ent.lastName = [[entity objectForKey:@"name"] objectForKey:@"last"];
            c_ent.lastFirstName = [[entity objectForKey:@"name"] objectForKey:@"lastFirst"];
            c_ent.firstLastName = [[entity objectForKey:@"name"] objectForKey:@"firstLast"];
            c_ent.groups = [entity objectForKey:@"groups"];
            c_ent.urn = [entity objectForKey:@"urn"];
            c_ent.id = [entity objectForKey:@"id"];
            c_ent.entityId = [entity objectForKey:@"id"];
            c_ent.me = [NSNumber numberWithBool:[c_ent.entityId isEqualToString:me]];
            c_ent.picture = [entity objectForKey:@"picture"];
            c_ent.email = [entity objectForKey:@"email"];
            
            PersonMeta *c_meta = [PersonMeta MR_createInContext:_context];
            c_meta.entityId = entity[@"meta"][@"entity"];
            c_meta.lastModified = entity[@"meta"][@"lastModified"];
            c_meta.createDate = entity[@"meta"][@"createDate"];
            c_meta.pinnedActivityOrder = entity[@"meta"][@"pinnedActivityOrder"];
            c_meta.activityOrder = entity[@"meta"][@"activityOrder"];
            c_meta.urn = entity[@"meta"][@"urn"];
            c_meta.metaId = entity[@"meta"][@"id"];
            
            c_ent.entityMeta = c_meta;
            
            NSLog(@"id:%@ - _id:%@", [entity objectForKey:@"id"], [entity objectForKey:@"_id"]);
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    @finally {
        [_context MR_saveToPersistentStoreAndWait];
    }
    
    
    return c_ent;
    
}

+ (PersonEntities *)updateEntities:(PersonEntities *)entity withDictionary:(NSDictionary *)dictionary withManagedContext:(NSManagedObjectContext *)context
{
    if (context) {
        _context = context;
    }
    else {
        _context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    long lastModifiedFromEntity = [entity.lastModified integerValue];
    long lastModifiedFromDictionary = [dictionary[@"lastModified"] integerValue];
    
    if (lastModifiedFromDictionary != lastModifiedFromEntity) {
        entity.lastModified = [dictionary objectForKey:@"lastModified"];
        entity.presence = [dictionary objectForKey:@"presence"];
        //entity.company = [dictionary objectForKey:@"company"];
        entity.tags = [dictionary objectForKey:@"tags"];
        entity.location = [dictionary objectForKey:@"location"];
        entity.firstName = [[dictionary objectForKey:@"name"] objectForKey:@"first"];
        entity.lastName = [[dictionary objectForKey:@"name"] objectForKey:@"last"];
        entity.lastFirstName = [[dictionary objectForKey:@"name"] objectForKey:@"lastFirst"];
        entity.firstLastName = [[dictionary objectForKey:@"name"] objectForKey:@"firstLast"];
        entity.groups = [dictionary objectForKey:@"groups"];
        //entity.urn = [dictionary objectForKey:@"urn"];
        //entity.id = [dictionary objectForKey:@"id"];
        //entity.entityId = [dictionary objectForKey:@"id"];
        //entity.me = [NSNumber numberWithBool:[entity.entityId isEqualToString:me]];
        entity.picture = [dictionary objectForKey:@"picture"];
        entity.email = [dictionary objectForKey:@"email"];
        
        entity.entityMeta.entityId = dictionary[@"meta"][@"entity"];
        entity.entityMeta.lastModified = dictionary[@"meta"][@"lastModified"];
        entity.entityMeta.createDate = dictionary[@"meta"][@"createDate"];
        entity.entityMeta.pinnedActivityOrder = dictionary[@"meta"][@"pinnedActivityOrder"];
        entity.entityMeta.activityOrder = dictionary[@"meta"][@"activityOrder"];
        entity.entityMeta.urn = dictionary[@"meta"][@"urn"];
        entity.entityMeta.metaId = dictionary[@"meta"][@"id"];
        
        //NSLog(@"id:%@ - _id:%@", [dictionary objectForKey:@"id"], [dictionary objectForKey:@"_id"]);
        
        [_context MR_saveToPersistentStoreAndWait];
    }
    
    return entity;
}


@end
