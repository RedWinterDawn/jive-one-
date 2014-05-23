//
//  JCSearchBar.m
//  JiveOne
//
//  Created by Doug on 5/19/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCSearchBar.h"

@implementation JCSearchBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
    }
    return self;
}
-(void)layoutSubviews{
    [super layoutSubviews];
    [self setShowsCancelButton:NO animated:NO];
    [self setBarStyle:UIBarStyleDefault];
    [self setPlaceholder:@"Search                                                      "];
    // yes this is necessary see: http://stackoverflow.com/questions/19289406/uisearchbar-search-icon-isnot-left-aligned-in-ios7
    [self setImage:[UIImage imageNamed:@"searchGray2.png"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
//    [self setImage:[UIImage imageNamed:@"search2.png"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateHighlighted];

}



@end
