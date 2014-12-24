//
//  JCVoiceViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 9/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Voicemail;

@interface JCVoicemailViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, strong) Voicemail *voicemail;

@end
