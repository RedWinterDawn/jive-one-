//
//  JCTransferViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDialerViewController.h"
#import "JCCallCardManager.h"

@class JCTransferViewController;

@protocol JCTransferViewControllerDelegate <NSObject>

-(void)transferViewController:(JCTransferViewController *)controller shouldDialNumber:(NSString *)dialString;
-(void)shouldCancelTransferViewController:(JCTransferViewController *)controller;

@end

@interface JCTransferViewController : JCDialerViewController

@property (nonatomic, weak) id <JCTransferViewControllerDelegate> delegate;
@property (nonatomic) JCCallCardDialTypes transferCallType;

-(IBAction)cancel:(id)sender;

@end
