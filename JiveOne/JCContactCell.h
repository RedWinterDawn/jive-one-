//
//  JCContactCell.h
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonCell.h"
#import "InternalExtension.h"

@interface JCContactCell : JCPersonCell

@property (nonatomic, weak) IBOutlet UIButton *favoriteBtn;

@property (nonatomic, strong) InternalExtension *contact;

- (IBAction)toggleFavoriteStatus:(id)sender;

@end
