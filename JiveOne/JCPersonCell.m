//
//  JCPersonCell.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonCell.h"

#import "Extension.h"

@implementation JCPersonCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    id <JCPersonDataSource> person = self.person;
    self.textLabel.text = person.titleText;
    self.detailTextLabel.text = person.detailText;
}

#pragma mark - Setters -

- (void)setPerson:(id<JCPersonDataSource>)person
{
    _person = person;
    if ([person isKindOfClass:[Extension class]]) {
        Extension *jiveContact = (Extension *)person;
        self.identifier = jiveContact.jrn;
    }
}

@end