//
//  JCConferenceCallCard.h
//  JiveOne
//
//  Created by Robert Barclay on 10/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneCall.h"

@interface JCPhoneConferenceCall : JCPhoneCall

@property (nonatomic, readonly) NSArray *calls;
@property (nonatomic, readonly) BOOL isHolding;

-(instancetype)initWithLineSessions:(NSSet *)sessions;

@end
