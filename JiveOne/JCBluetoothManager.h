//
//  JCBluetoothManager.h
//  JiveOne
//
//  Created by Robert Barclay on 11/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;

@interface JCBluetoothManager : NSObject

-(instancetype)initWithLaunchOptions:(NSDictionary *)launchOptions;

-(void)enableBluetoothAudio;

@end