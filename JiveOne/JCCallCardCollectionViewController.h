//
//  JCCallCardCollectionViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCCallCardViewCell.h"

@class JCCallCardCollectionViewController;

@protocol JCCallCardCollectionViewControllerDelegate <NSObject>

-(void)callCardCollectionViewController:(JCCallCardCollectionViewController *)viewController configureCell:(UICollectionViewCell *)callCardCell callIdentifier:(NSString *)identifier;

@end


@interface JCCallCardCollectionViewController : UICollectionViewController

@property (nonatomic, weak) IBOutlet id<JCCallCardCollectionViewControllerDelegate> delegate;

-(void)addCall:(NSString *)callIdentifier;
-(void)removeCall:(NSString *)callIdentifier;

-(void)addIncommingCall:(NSString *)callIdentifier;
-(void)transferIncommingCallToCall:(NSString *)callIdentifier;
-(void)removeIncommingCall:(NSString *)callIdentifier;

@end
