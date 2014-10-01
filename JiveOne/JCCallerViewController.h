//
//  JCCallerViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCCallerViewController : UIViewController

@property (nonatomic, strong) NSString *dialString;
@property (nonatomic) bool speaker;
@property (nonatomic) bool mute;

-(IBAction)warmTransfer:(id)sender;
-(IBAction)blindTransfer:(id)sender;
-(IBAction)speaker:(id)sender;
-(IBAction)keypad:(id)sender;
-(IBAction)addCall:(id)sender;
-(IBAction)mute:(id)sender;



@end
