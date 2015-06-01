//
//  JCPlayPauseButton.h
//  JiveOne
//
//  Created by Robert Barclay on 5/29/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

@interface JCPlayPauseButton : UIButton

// Configurable Properties
@property (nonatomic, strong) UIImage *pauseImage;
@property (nonatomic, strong) UIImage *playImage;
@property (nonatomic, strong) UIColor *selectedColor;

// State Properties.
@property (nonatomic, getter=isPaused) BOOL paused;

@end
