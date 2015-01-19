//
//  JCConferenceCallCard.h
//  JiveOne
//
//  Created by Robert Barclay on 10/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCard.h"

@interface JCConferenceCallCard : JCCallCard

@property (nonatomic, readonly) NSArray *calls;
@property (nonatomic, readonly) BOOL isHolding;

-(instancetype)initWithLineSessions:(NSSet *)sessions;

@end
