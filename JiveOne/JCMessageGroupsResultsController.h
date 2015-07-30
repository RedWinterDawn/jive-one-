//
//  JCConversationGroups.h
//  JiveOne
//
//  Created by Robert Barclay on 2/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import "JCFetchedResultsController.h"

@interface JCMessageGroupsResultsController : JCFetchedResultsController

-(instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest pbx:(PBX *)pbx;

@end

