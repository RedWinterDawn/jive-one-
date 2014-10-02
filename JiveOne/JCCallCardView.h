//
//  JCCallCard.h
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JCCallCardView;

@protocol JCCallCardViewDelegate <NSObject>

-(void)callCardViewShouldHangUp:(JCCallCardView *)view;
-(void)callCardViewShouldHold:(JCCallCardView *)view;

@end


@interface JCCallCardView : UIView


@property (nonatomic, weak) id<JCCallCardViewDelegate> delegate;
@property (nonatomic, strong) NSString *identifer;

-(IBAction)hangup:(id)sender;
-(IBAction)placeOnHold:(id)sender;

@end


@interface JCCallCardView (NibLoading)

+(JCCallCardView *)createCallCardWithIdentifier:(NSString *)identifier delegate:(id<JCCallCardViewDelegate>)delegate;

@end