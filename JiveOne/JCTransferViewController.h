//
//  JCTransferViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDialerViewController.h"

@class JCTransferViewController;

@protocol JCTransferViewControllerDelegate <NSObject>

-(void)transferViewController:(JCTransferViewController *)controller shouldDialNumber:(NSString *)dialString;
-(void)shouldCancelTransferViewController:(JCTransferViewController *)controller;

@end

typedef enum : NSUInteger {
    JCTransferBlind = 0,
    JCTransferWarm,
    JCTransferHold,
} JCTransferType;

@interface JCTransferViewController : JCDialerViewController

@property (nonatomic, weak) id <JCTransferViewControllerDelegate> delegate;
@property (nonatomic) JCTransferType transferType;

-(IBAction)cancel:(id)sender;

@end
