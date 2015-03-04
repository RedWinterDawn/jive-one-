//
//  JCBluetoothManager.h
//  JiveOne
//
//  Created by Robert Barclay on 11/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;
@import AudioToolbox;

typedef enum : NSUInteger {
    JCPhoneAudioManagerOutputUnknown = 0,
    JCPhoneAudioManagerOutputLineOut,       /* Line level output on a dock connector */
    JCPhoneAudioManagerOutputHeadphones,    /* Headphone or headset output */
    JCPhoneAudioManagerOutputBluetooth,     /* Output on a Bluetooth A2DP device */
    JCPhoneAudioManagerOutputBluetoothLE,   /* Output on a Bluetooth Low Energy device */
    JCPhoneAudioManagerOutputReceiver,      /* The speaker you hold to your ear when on a phone call */
    JCPhoneAudioManagerOutputSpeaker,       /* Built-in speaker on an iOS device */
    JCPhoneAudioManagerOutputHDMI,          /* Output via High-Definition Multimedia Interface */
    JCPhoneAudioManagerOutputAirPlay,       /* Output on a remote Air Play device */
    JCPhoneAudioManagerOutputBluetoothHFP,  /* Input or output on a Bluetooth Hands-Free Profile device */
    JCPhoneAudioManagerOutputUSB,           /* Input or output on a Universal Serial Bus device */
    JCPhoneAudioManagerOutputCarAudio       /* Input or output via Car Audio */
} JCPhoneAudioManagerOutputType;

typedef enum : NSUInteger {
    JCPhoneAudioManagerInputUnknown = 0,
    JCPhoneAudioManagerInputLineIn,         /* Line level input on a dock connector */
    JCPhoneAudioManagerInputMicrophone,     /* Built-in microphone on an iOS device */
    JCPhoneAudioManagerInputHeadphonesMic,  /* Microphone on a wired headset.  Headset refers to an accessory that has headphone outputs paired with a microphone. */
    JCPhoneAudioManagerInputBluetoothHFP,   /* Input or output on a Bluetooth Hands-Free Profile device */
    JCPhoneAudioManagerInputUSB,            /* Input or output on a Universal Serial Bus device */
    JCPhoneAudioManagerInputCarAudio        /* Input or output via Car Audio */
} JCPhoneAudioManagerInputType;


@class JCPhoneAudioManager;

@protocol JCPhoneAudioManagerDelegate <NSObject>

-(void)phoneAudioManager:(JCPhoneAudioManager *)manager didChangeAudioRouteOutputType:(JCPhoneAudioManagerOutputType)outputType;
-(void)phoneAudioManager:(JCPhoneAudioManager *)manager didChangeAudioRouteInputType:(JCPhoneAudioManagerInputType)inputType;

@end

@interface JCPhoneAudioManager : NSObject

@property (nonatomic, weak) id<JCPhoneAudioManagerDelegate> delegate;

@property (nonatomic, readonly) JCPhoneAudioManagerInputType inputType;
@property (nonatomic, readonly) JCPhoneAudioManagerOutputType outputType;

- (void)engageAudioSession;
- (void)disengageAudioSession;

@end

@interface JCPhoneAudioManager (Alerts)

- (void)vibrate;                                    // Single vibrate.
- (void)startRepeatingVibration:(BOOL)repeating;    // Repeating Vibration
- (void)ring;                                       // Single ring.
- (void)startRepeatingRingtone:(BOOL)repeating;     // Repeating Ring.
- (void)stop;                                       // Stops repeating events.
- (void)startRingback;                              // Starts Ringback.

@end