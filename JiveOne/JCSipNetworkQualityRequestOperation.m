//
//  JCSipNetworkQualityRequestOperation.m
//  JiveOne
//
//  Created by Robert Barclay on 1/29/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSipNetworkQualityRequestOperation.h"

#define CURRENT_BUFFER_SIZE_THRESHOLD 200
#define CURRENT_PACKET_LOSS_RATE_THRESHOLD 1000

@implementation JCSipNetworkQualityRequestOperation

-(instancetype)initWithSessionId:(NSInteger)sessionId portSipSdk:(PortSIPSDK *)portSipSdk
{
    self = [super init];
    if (self) {
        _sessionId = sessionId;
        _portSipSdk = portSipSdk;
    }
    return self;
}

-(void)main
{
    BOOL errorCode = [_portSipSdk getNetworkStatistics:_sessionId
                                   currentBufferSize:&_currentBufferSize
                                 preferredBufferSize:&_preferedBufferSize
                               currentPacketLossRate:&_currentPacketLossRate
                                  currentDiscardRate:&_currentDiscardRate
                                   currentExpandRate:&_currentExpandRate
                               currentPreemptiveRate:&_currentPremptiveRate
                               currentAccelerateRate:&_currentAccelerateRate];
    if (errorCode) {
        _error = [NSError errorWithDomain:@"SipNetworkQualityRequestError" code:errorCode userInfo:nil];
    }
}

-(BOOL)isBelowNetworkThreshold
{
    if (_currentBufferSize > 200 || _currentPacketLossRate > 1000)
        return YES;
    return NO;
}

@end
