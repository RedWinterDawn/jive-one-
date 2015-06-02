//
//  JCVoicemailManager.h
//  JiveOne
//
//  Created by Robert Barclay on 3/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import "JCSocketManager.h"

@interface JCVoicemailManager : JCSocketManager

+(void)subscribeToLine:(Line *)line;

@end