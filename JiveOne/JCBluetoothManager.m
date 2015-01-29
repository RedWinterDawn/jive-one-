//
//  JCBluetoothManager.m
//  JiveOne
//
//  Created by Robert Barclay on 11/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import AVFoundation;

#import "JCBluetoothManager.h"

@interface JCBluetoothManager() <CBCentralManagerDelegate> //, CBPeripheralDelegate, CBPeripheralManagerDelegate>
{
    CBCentralManager *_bluetoothCentralManager;
}

@end

@implementation JCBluetoothManager

-(instancetype)initWithLaunchOptions:(NSDictionary *)launchOptions
{
    self = [self init];
    if (self) {
        
        // if not live central manager and peripheral manager
        //NSArray *centralManagerIdentifiers = launchOptions[UIApplicationLaunchOptionsBluetoothCentralsKey];
//        NSLog(@"CENTRAL: restore identifiers count :%lu",(unsigned long)centralManagerIdentifiers.count);
        
        //NSArray *peripheralManagerIdentifiers = launchOptions[UIApplicationLaunchOptionsBluetoothPeripheralsKey];
//        NSLog(@"PERIPHERAL: restore identifiers count :%lu",(unsigned long)peripheralManagerIdentifiers.count);
    }
    return self;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self enableBluetoothAudio];
        
//        _bluetoothCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(myInterruptionSelector:) name:AVAudioSessionInterruptionNotification object:nil];
        [center addObserver:self selector:@selector(audioSessionRouteChangeSelector:) name:AVAudioSessionRouteChangeNotification object:nil];
        [center addObserver:self selector:@selector(audioSessionMediaServicesWereLostSelector:) name:AVAudioSessionMediaServicesWereLostNotification object:nil];
        [center addObserver:self selector:@selector(audioSessionMediaServicesWereResetSelector:) name:AVAudioSessionMediaServicesWereResetNotification object:nil];
//        [center addObserver:self selector:@selector(audioSessionSilenceSecondaryAudioHintSelector:) name:AVAudioSessionSilenceSecondaryAudioHintNotification object:nil];
    }
    return self;
}

#pragma mark - Public Methods

/* Access the Audio Session singlton and modify the AVAudioSessionPlayAndRecord property to allow Bluetooth.
 */
-(void)enableBluetoothAudio
{
    // deactivate session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (![session setActive:NO error: nil]) {
        NSLog(@"deactivationError");
    }
    
    __autoreleasing NSError *error;
    
    // set audio session category AVAudioSessionCategoryPlayAndRecord options AVAudioSessionCategoryOptionAllowBluetooth
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:&error]) {
        NSLog(@"setCategoryError");
    }
    
    if (![session setMode:AVAudioSessionModeVoiceChat error:&error]) {
        NSLog(@"AVAudioSession error setting category:%@",error);
    }
    
    if (![session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error]) {
        NSLog(@"AVAudioSession error setting mode:%@",error);
    }
    
    if (![session setPreferredOutputNumberOfChannels:0 error:&error]) {
        NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
    }
    
    // activate audio session
    if (![session setActive:YES error:nil]) {
        NSLog(@"activationError");
    }
}

#pragma mark - Notification Handlers -

#pragma mark AVAudioSession

/* Registered listeners will be notified when the system has interrupted the audio session and when
 the interruption has ended.  Check the notification's userInfo dictionary for the interruption type -- either begin or end.
 In the case of an end interruption notification, check the userInfo dictionary for AVAudioSessionInterruptionOptions that
 indicate whether audio playback should resume.
 */
- (void)myInterruptionSelector:(NSNotification *)notification {
    
//    NSLog(@"Audio Session Interuption %@", [notification.userInfo description]);
    
    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    NSArray *inputsForRoute = currentRoute.inputs;
    NSArray *outputsForRoute = currentRoute.outputs;
    AVAudioSessionPortDescription *outPortDesc = [outputsForRoute objectAtIndex:0];
    NSLog(@"current outport type %@", outPortDesc.portType);
    AVAudioSessionPortDescription *inPortDesc = [inputsForRoute objectAtIndex:0];
    NSLog(@"current inPort type %@", inPortDesc.portType);
}

/* Registered listeners will be notified when a route change has occurred.  Check the notification's userInfo dictionary for the
 route change reason and for a description of the previous audio route.
 */
- (void)audioSessionRouteChangeSelector:(NSNotification*)notification {
    
//    NSLog(@"Audio Session Route Changed %@", [notification.userInfo description]);
    
    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    NSArray *inputsForRoute = currentRoute.inputs;
    NSArray *outputsForRoute = currentRoute.outputs;
    AVAudioSessionPortDescription *outPortDesc = [outputsForRoute objectAtIndex:0];
    NSLog(@"current outport type %@", outPortDesc.portType);
    AVAudioSessionPortDescription *inPortDesc = [inputsForRoute objectAtIndex:0];
    NSLog(@"current inPort type %@", inPortDesc.portType);
}

/* Registered listeners will be notified if the media server is killed.  In the event that the server is killed,
 take appropriate steps to handle requests that come in before the server resets.  See Technical Q&A QA1749.
 */
-(void)audioSessionMediaServicesWereLostSelector:(NSNotification *)notification
{
    NSLog(@"Audio Session Media Services Were Lost %@", [notification.userInfo description]);
}

/* Registered listeners will be notified when the media server restarts.  In the event that the server restarts,
 take appropriate steps to re-initialize any audio objects used by your application.  See Technical Q&A QA1749.
 */
-(void)audioSessionMediaServicesWereResetSelector:(NSNotification *)notification
{
    NSLog(@"Audio Session Media Services Were Reset %@", [notification.userInfo description]);
}

/* Registered listeners that are currently in the foreground and have active audio sessions will be notified
 when primary audio from other applications starts and stops.  Check the notification's userInfo dictionary
 for the notification type -- either begin or end.
 Foreground applications may use this notification as a hint to enable or disable audio that is secondary
 to the functionality of the application. For more information, see the related property secondaryAudioShouldBeSilencedHint.
 */
-(void)audioSessionSilenceSecondaryAudioHintSelector:(NSNotification *)notification
{
    NSLog(@"Audio Session Silence Secondary Audio %@", [notification.userInfo description]);
}

#pragma mark - Delegate Handlers -

#pragma mark CBCentralManagerDelegate

/*!
 *  @method centralManagerDidUpdateState:
 *
 *  @param central  The central manager whose state has changed.
 *
 *  @discussion     Invoked whenever the central manager's state has been updated. Commands should only be issued when the state is
 *                  <code>CBCentralManagerStatePoweredOn</code>. A state below <code>CBCentralManagerStatePoweredOn</code>
 *                  implies that scanning has stopped and any connected peripherals have been disconnected. If the state moves below
 *                  <code>CBCentralManagerStatePoweredOff</code>, all <code>CBPeripheral</code> objects obtained from this central
 *                  manager become invalid and must be retrieved or discovered again.
 *
 *  @see            state
 *
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOff){
        NSLog(@"BLE OFF");
    }
    else if (central.state == CBCentralManagerStatePoweredOn){
        
        NSLog(@"BLE ON");
        
        NSArray *array = [central retrieveConnectedPeripheralsWithServices:@[]];
        
        NSLog(@"%@", [array description]);
    }
    else if (central.state == CBCentralManagerStateUnknown){
        NSLog(@"NOT RECOGNIZED");
    }
    else if(central.state == CBCentralManagerStateUnsupported){
        NSLog(@"BLE NOT SUPPORTED");
    }
}

/*!
 *  @method centralManager:willRestoreState:
 *
 *  @param central      The central manager providing this information.
 *  @param dict			A dictionary containing information about <i>central</i> that was preserved by the system at the time the app was terminated.
 *
 *  @discussion			For apps that opt-in to state preservation and restoration, this is the first method invoked when your app is relaunched into
 *						the background to complete some Bluetooth-related task. Use this method to synchronize your app's state with the state of the
 *						Bluetooth system.
 *
 *  @seealso            CBCentralManagerRestoredStatePeripheralsKey;
 *  @seealso            CBCentralManagerRestoredStateScanServicesKey;
 *  @seealso            CBCentralManagerRestoredStateScanOptionsKey;
 *
 */
- (void)centralManager:(CBCentralManager *)central
      willRestoreState:(NSDictionary *)dict
{
    
}

/*!
 *  @method centralManager:didRetrievePeripherals:
 *
 *  @param central      The central manager providing this information.
 *  @param peripherals  A list of <code>CBPeripheral</code> objects.
 *
 *  @discussion         This method returns the result of a {@link retrievePeripherals} call, with the peripheral(s) that the central manager was
 *                      able to match to the provided UUID(s).
 *
 */
- (void)centralManager:(CBCentralManager *)central
didRetrievePeripherals:(NSArray *)peripherals
{
    
}

/*!
 *  @method centralManager:didRetrieveConnectedPeripherals:
 *
 *  @param central      The central manager providing this information.
 *  @param peripherals  A list of <code>CBPeripheral</code> objects representing all peripherals currently connected to the system.
 *
 *  @discussion         This method returns the result of a {@link retrieveConnectedPeripherals} call.
 *
 */
- (void)centralManager:(CBCentralManager *)central
didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
    
}

/*!
 *  @method centralManager:didDiscoverPeripheral:advertisementData:RSSI:
 *
 *  @param central              The central manager providing this update.
 *  @param peripheral           A <code>CBPeripheral</code> object.
 *  @param advertisementData    A dictionary containing any advertisement and scan response data.
 *  @param RSSI                 The current RSSI of <i>peripheral</i>, in dBm. A value of <code>127</code> is reserved and indicates the RSSI
 *								was not available.
 *
 *  @discussion                 This method is invoked while scanning, upon the discovery of <i>peripheral</i> by <i>central</i>. A discovered peripheral must
 *                              be retained in order to use it; otherwise, it is assumed to not be of interest and will be cleaned up by the central manager. For
 *                              a list of <i>advertisementData</i> keys, see {@link CBAdvertisementDataLocalNameKey} and other similar constants.
 *
 *  @seealso                    CBAdvertisementData.h
 *
 */
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI{
    
}

/*!
 *  @method centralManager:didConnectPeripheral:
 *
 *  @param central      The central manager providing this information.
 *  @param peripheral   The <code>CBPeripheral</code> that has connected.
 *
 *  @discussion         This method is invoked when a connection initiated by {@link connectPeripheral:options:} has succeeded.
 *
 */
- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    
}

/*!
 *  @method centralManager:didFailToConnectPeripheral:error:
 *
 *  @param central      The central manager providing this information.
 *  @param peripheral   The <code>CBPeripheral</code> that has failed to connect.
 *  @param error        The cause of the failure.
 *
 *  @discussion         This method is invoked when a connection initiated by {@link connectPeripheral:options:} has failed to complete. As connection attempts do not
 *                      timeout, the failure of a connection is atypical and usually indicative of a transient issue.
 *
 */
- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    
}

/*!
 *  @method centralManager:didDisconnectPeripheral:error:
 *
 *  @param central      The central manager providing this information.
 *  @param peripheral   The <code>CBPeripheral</code> that has disconnected.
 *  @param error        If an error occurred, the cause of the failure.
 *
 *  @discussion         This method is invoked upon the disconnection of a peripheral that was connected by {@link connectPeripheral:options:}. If the disconnection
 *                      was not initiated by {@link cancelPeripheralConnection}, the cause will be detailed in the <i>error</i> parameter. Once this method has been
 *                      called, no more methods will be invoked on <i>peripheral</i>'s <code>CBPeripheralDelegate</code>.
 *
 */
- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    
}

@end
