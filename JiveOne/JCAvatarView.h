//
//  JCAvatarView.h
//  JiveOne
//
//  Created by Robert Barclay on 2/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCRoundedView.h"
#import "Person.h"

@interface JCAvatarView : JCRoundedView

@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *name;

@property (strong, nonatomic) Person *person;

@end
