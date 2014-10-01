//
//  JCCallCard.h
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JCCallCardViewCell;

@protocol JCCallCardViewDelegate <NSObject>

-(void)callCardViewShouldHangUp:(JCCallCardViewCell *)view;
-(void)callCardViewShouldHold:(JCCallCardViewCell *)view;

@end


@interface JCCallCardViewCell : UICollectionViewCell


@property (nonatomic, weak) id<JCCallCardViewDelegate> delegate;
@property (nonatomic, strong) NSString *identifer;

-(IBAction)hangup:(id)sender;
-(IBAction)placeOnHold:(id)sender;

@end


@interface JCCallCardViewCell (NibLoading)

+(JCCallCardViewCell *)createCallCardWithIdentifier:(NSString *)identifier delegate:(id<JCCallCardViewDelegate>)delegate;

@end