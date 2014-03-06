//
//  JCOmniPresence.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/18/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClientEntities.h"
#import "Presence.h"

@interface JCOmniPresence : NSObject

+(instancetype)sharedInstance;

- (ClientEntities*)me;

- (ClientEntities*)entityByEntityId:(NSString*)entityId;

- (Presence*)presenceByEntityId:(NSString*)entityId;

- (void)truncateAllTablesAtLogout;

@end
