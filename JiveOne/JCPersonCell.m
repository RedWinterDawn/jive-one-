//
//  JCPersonCell.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonCell.h"

#import "JiveContact.h"

@implementation JCPersonCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    Person *person = self.person;
    self.textLabel.text = person.name;
    
    if ([person isKindOfClass:[JiveContact class]]) {
        JiveContact *jiveContact = (JiveContact *)person;
        self.detailTextLabel.text = jiveContact.detailText;
    }
    
    
}

#pragma mark - Setters -

- (void)setPerson:(Person *)person
{
    _person = person;
    if ([person isKindOfClass:[JiveContact class]]) {
        JiveContact *jiveContact = (JiveContact *)person;
        self.identifier = jiveContact.jrn;
    }
}

@end