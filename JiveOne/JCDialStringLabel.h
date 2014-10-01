//
//  JCDialStringTextView.h
//  JiveOne
//
//  Created by Robert Barclay on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JCDialStringLabelDelegate <NSObject>

@optional
-(void)didUpdateDialString:(NSString *)dialString;

@end

@interface JCDialStringLabel : UILabel

@property (nonatomic, weak) IBOutlet id <JCDialStringLabelDelegate> delegate;
@property (nonatomic, readonly) NSString *dialString;

-(void)append:(NSString *)string;

-(void)backspace;
-(void)clear;

@end
