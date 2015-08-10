//
//  JCSipNetworkQualityRequestOperation.h
//  JiveOne
//
//  Created by Robert Barclay on 1/29/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import <PortSIPLib/PortSIPSDK.h>

@interface JCPhoneSipSessionNetworkQualityRequestOperation : NSOperation

@property (nonatomic, readonly) PortSIPSDK *portSipSdk;
@property (nonatomic, readonly) NSInteger sessionId;

// Statistics.
@property (nonatomic, readonly) int currentBufferSize;
@property (nonatomic, readonly) int preferedBufferSize;
@property (nonatomic, readonly) int currentPacketLossRate;
@property (nonatomic, readonly) int currentDiscardRate;
@property (nonatomic, readonly) int currentExpandRate;
@property (nonatomic, readonly) int currentPremptiveRate;
@property (nonatomic, readonly) int currentAccelerateRate;

// Threshold Checking
@property (nonatomic) BOOL isBelowNetworkThreshold;

// Error
@property (nonatomic, readonly) NSError *error;

-(instancetype)initWithSessionId:(NSInteger)sessionId portSipSdk:(PortSIPSDK *)portSipSdk;

@end
