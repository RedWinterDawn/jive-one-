//
//  JCDialStringTextView.h
//  JiveOne
//
//
//
//  Created by Robert Barclay on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JCFormattedPhoneNumberLabelDelegate <NSObject>

@optional
-(void)didUpdateDialString:(NSString *)dialString;

@end

@interface JCFormattedPhoneNumberLabel : UILabel

@property (nonatomic, weak) IBOutlet id <JCFormattedPhoneNumberLabelDelegate> delegate;
@property (nonatomic) NSString *dialString;

// Appends a string to the internal dial string at the end of the string.
-(void)append:(NSString *)string;

// Removes the last character of the dial string.
-(void)backspace;

// Clear the internal dial string.
-(void)clear;

@end
