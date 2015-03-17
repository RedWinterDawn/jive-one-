//
//  JCVoicemailManager.h
//  JiveOne
//
//  Created by Robert Barclay on 3/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

@interface JCVoicemailManager : NSObject

@end

@interface JCVoicemailManager (Singleton)

+(instancetype)sharedManager;
+(void)subscribeToLine:(Line *)line;

@end