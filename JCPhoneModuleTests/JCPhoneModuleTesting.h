//
//  Testing.h
//  JiveOne
//
//  Created by Robert Barclay on 8/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

// TDD/BDD Testing framework. Built on top of XCTests.
#import "Specta.h"

// Expectation libraries that makes Asserts more human readable.
#define EXP_SHORTHAND
#import "Expecta.h"

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

// Mocking Frameworks
#import <OCMock/OCMock.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>