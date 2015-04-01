//
//  JCMessageManager.h
//  JiveOne
//
//  Created by P Leonard on 4/1/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSocketManager.h"

@interface JCMessageManager : JCSocketManager

+(void)subscribeToLine(Line *)line;

@end
