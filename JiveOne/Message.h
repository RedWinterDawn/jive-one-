//
//  Message.h
//  JiveOne
//
//  Created by Robert Barclay on 1/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <JSQMessagesViewController/JSQMessageData.h>
#import "RecentEvent.h"

@interface Message : RecentEvent <JSQMessageData>

@property (nonatomic, retain) NSString * text;

@end
