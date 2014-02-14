//
//  JCVoipViewController.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <SocketRocket/SRWebSocket.h>

@interface JCVoipViewController : UIViewController <NSStreamDelegate, SRWebSocketDelegate>

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSMutableString *communicationLog;
@property (nonatomic) BOOL sentPing;

@property (strong, nonatomic) IBOutlet UITextField *txtIP;
@property (strong, nonatomic) IBOutlet UITextField *txtPort;
@property (strong, nonatomic) IBOutlet UITextView *txtReceivedData;

- (IBAction)didTapConnect:(id)sender;
- (IBAction)didTapSession:(id)sender;
- (IBAction)didTapSubscription:(id)sender;

@end
