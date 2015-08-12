//
//  JCSettings.m
//  Pods
//
//  Created by Robert Barclay on 8/6/15.
//
//

#import "JCSettings.h"

@implementation JCSettings

-(instancetype)initWithDefaults:(NSUserDefaults *)userDefaults
{
    self = [super init];
    if (self) {
        _userDefaults = userDefaults;
    }
    return self;
}

-(instancetype)init
{
    return [self initWithDefaults:[NSUserDefaults standardUserDefaults]];
}

-(void)loadDefaultsFromFile:(NSString *)file
{
    [self loadDefaultsFromFile:file bundle:[NSBundle bundleForClass:[self class]]];
}

-(void)loadDefaultsFromFile:(NSString *)file bundle:(NSBundle *)bundle
{
    NSString *extension = [file pathExtension];
    NSString *fileName = [file stringByDeletingPathExtension];
    
    NSString *defaultsFilePath = [bundle pathForResource:fileName ofType:extension];
    if (!defaultsFilePath) {
        NSLog(@"Unable to load defaults from file: %@", file);
        return;
    }
    NSDictionary *defaultPreferences = [NSDictionary dictionaryWithContentsOfFile:defaultsFilePath];
    if (!defaultPreferences) {
        NSLog(@"Unable to load defaults from file path: %@", defaultsFilePath);
        return;
    }
    [self loadDefaults:defaultPreferences];
}

-(void)loadDefaults:(NSDictionary *)defaults
{
    [self.userDefaults registerDefaults:defaults];
}

#pragma mark - Helper Methods -

-(void)setBoolValue:(BOOL)value forKey:(NSString *)key
{
    [self willChangeValueForKey:key];
    NSUserDefaults *defaults = self.userDefaults;
    [defaults setBool:value forKey:key];
    [defaults synchronize];
    [self didChangeValueForKey:key];
}

-(void)setValue:(NSString *)value forKey:(NSString *)key
{
    [self willChangeValueForKey:key];
    NSUserDefaults *defaults = self.userDefaults;
    [defaults setValue:value forKey:key];
    [defaults synchronize];
    [self didChangeValueForKey:key];
}

-(void)setFloatValue:(float)value forKey:(NSString *)key
{
    [self willChangeValueForKey:key];
    NSUserDefaults *defaults = self.userDefaults;
    [defaults setFloat:value forKey:key];
    [defaults synchronize];
    [self didChangeValueForKey:key];
}

@end