//
//  JCPbxConfigurationViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 12/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLinePickerViewController.h"
#import "JCUserManager.h"
#import "PBX.h"
#import "Line.h"

@interface JCLinePickerViewController ()

@property (strong, nonatomic) NSArray *lines;

@end

@implementation JCLinePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.backgroundVisualEffectsView.backgroundView = self.navigationController.view;
    self.pickerViewVisualEffectsView.backgroundView = self.view;
    
    JCUserManager *authenticationManger = self.userManager;
    User *user = authenticationManger.user;
    Line *line = authenticationManger.line;
    
    self.lines = [Line MR_findByAttribute:@"pbx.user" withValue:user andOrderBy:@"number" ascending:YES];
    [self.selectBtn setTitle:[self titleForLine:line] forState:UIControlStateNormal];
    
    // Select the line that is currently selected by the authentication manager.
    if (line && [_lines containsObject:line]) {
        NSInteger index = [_lines indexOfObject:line];
        [self.pickerView selectRow:index inComponent:0 animated:NO];
    }
}

-(NSString *)titleForLine:(Line *)line
{
    return [NSString stringWithFormat:@"%@ on %@", line.number, line.pbx.name];
}

-(NSString *)titleForRow:(NSInteger)row
{
    Line *line = [_lines objectAtIndex:row];
    return [self titleForLine:line];
}

-(NSInteger)numberOfRows
{
    return [_lines count];
}

- (IBAction)done:(id)sender {
    [super done:sender];
    
    NSInteger row = [self.pickerView selectedRowInComponent:0];
    Line *line  = [_lines objectAtIndex:row];
    [self.selectBtn setTitle:[self titleForLine:line] forState:UIControlStateNormal];
}

-(IBAction)close:(id)sender {
    
    NSInteger row = [self.pickerView selectedRowInComponent:0];
    Line *line  = [_lines objectAtIndex:row];
    NSArray *lines = _lines;
    for (Line *item in lines) {
        if (line == item){
            item.active = TRUE;
        }
        else{
            item.active = FALSE;
        }
    }
    
    // If we have changes, save them.
    if (line.managedObjectContext.hasChanges) {
        __autoreleasing NSError *error;
        if(![line.managedObjectContext save:&error])
            NSLog(@"%@", [error description]);
    }
    
    self.userManager.line = line;
    [super close:sender];
}

@end
