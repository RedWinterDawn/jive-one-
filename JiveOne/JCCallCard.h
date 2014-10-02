//
//  JCCall.h
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCCallCard : NSObject

@property (nonatomic, strong) NSString *identifer;
@property (nonatomic, strong) NSString *callerId;
@property (nonatomic, strong) NSString *dialNumber;

@property (nonatomic, strong) NSDate *started;
@property (nonatomic, strong) NSDate *holdStarted;

@property (nonatomic) BOOL hold;

-(void)endCall;

@end
