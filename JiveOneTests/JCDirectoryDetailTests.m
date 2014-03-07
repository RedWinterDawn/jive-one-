//
//  JCDirectoryDetailTests.m
//  
//
//  Created by Doug Leonard on 2/20/14.
//
//

#import <XCTest/XCTest.h>
#import "JCDirectoryDetailViewController.h"
#import "JCAuthenticationManager.h"

@interface JCDirectoryDetailTests : XCTestCase
@property (nonatomic, strong) JCDirectoryDetailViewController *JCDDVC;
@end

@implementation JCDirectoryDetailTests

- (void)setUp
{
    [super setUp];
    
    // test.my.jive.com token for user jivetesting10@gmail.com
    NSString *token = [[JCAuthenticationManager sharedInstance] getAuthenticationToken];
    if ([self stringIsNilOrEmpty:token]) {
        if ([self stringIsNilOrEmpty:[[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"]]) {
            NSString *testToken = @"c8124461-0b9b-473b-a22e-fbf62feffa11";
            [[JCAuthenticationManager sharedInstance] didReceiveAuthenticationToken:testToken];
        }
    }
    
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.JCDDVC = [[JCDirectoryDetailViewController alloc]initWithStyle:UITableViewStyleGrouped];
    self.JCDDVC.tableView = [[UITableView alloc] initWithFrame:CGRectZero];
    [self forceLoadingOfTheView];
//    self.JCDDVC.tableView.dataSource
}

-(BOOL)stringIsNilOrEmpty:(NSString*)aString {
    return !(aString && aString.length);
}

- (void)forceLoadingOfTheView
{
    XCTAssertNotNil(self.JCDDVC.tableView, @"tableview is Nil");
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

///This will change from time to time, but since we use a C Constant, this test will help point us in the right direction when we cant figure out why new sections we add dont display on screen.
- (void)testNumberOfSectionsInTableView
{
    XCTAssertTrue([self.JCDDVC numberOfSectionsInTableView:self.JCDDVC.tableView] == 1, @"Number of sections in table should be 1");

}

- (void)testNumberOfCellsInSection
{
    
    XCTAssertTrue([self.JCDDVC tableView:self.JCDDVC.tableView numberOfRowsInSection:0] == 3, @"Number of cells in section should be 3");
    XCTAssertTrue([self.JCDDVC tableView:self.JCDDVC.tableView numberOfRowsInSection:1] == 0, @"Number of cells in all other sections should be 0");
    XCTAssertTrue([self.JCDDVC tableView:self.JCDDVC.tableView numberOfRowsInSection:2] == 0, @"Number of cells in all other sections should be 0");
    XCTAssertTrue([self.JCDDVC tableView:self.JCDDVC.tableView numberOfRowsInSection:10] == 0, @"Number of cells in all other sections should be 0");

}

- (void)testCellForRowAtIndexPath
{
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0;
    
//    XCTAssertTrue([self.JCDDVC tableView:self.JCDDVC.tableView cellForRowAtIndexPath:indexPath], @"sp,e");
}

@end












