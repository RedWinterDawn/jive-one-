//
//  JCCallCard.h
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCLineSession.h"

@class JCCallCardView;

@protocol JCCallCardViewDelegate <NSObject>

-(void)callCardViewShouldHangUp:(JCCallCardView *)view;
-(void)callCardViewShouldHold:(JCCallCardView *)view;

@end


@interface JCCallCardView : UIView <JCLineSessionDelegate>


@property (nonatomic, weak) id<JCCallCardViewDelegate> delegate;
@property (nonatomic, strong) NSString *identifer;
@property (weak, nonatomic) IBOutlet UILabel *callTitle;
@property (weak, nonatomic) IBOutlet UILabel *callDetail;
@property (weak, nonatomic) IBOutlet UILabel *callTimer;
@property (nonatomic, strong) JCLineSession *lineSession;

-(IBAction)hangup:(id)sender;
-(IBAction)placeOnHold:(id)sender;

@end


@interface JCCallCardView (NibLoading)

+(JCCallCardView *)createCallCardWithIdentifier:(NSString *)identifier delegate:(id<JCCallCardViewDelegate>)delegate;

@end