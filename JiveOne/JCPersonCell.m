//
//  JCPersonCell.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonCell.h"

@implementation JCPersonCell

@synthesize textLabel;
@synthesize detailTextLabel;

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    Person *person = self.person;
    self.textLabel.text = person.name;
    self.detailTextLabel.text = person.detailText;
}

#pragma mark - Setters -

- (void)setPerson:(Person *)person
{
    _person = person;
    self.identifier = person.jrn;
}

@end