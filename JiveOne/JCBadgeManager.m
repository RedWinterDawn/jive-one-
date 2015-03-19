//
//  JCBadgeManager.m
//  JiveOne
//
//  Created by Robert Barclay on 10/31/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCBadgeManager.h"
#import "RecentEvent.h"
#import "JCBadges.h"

static const UIUserNotificationType USER_NOTIFICATION_TYPES_REQUIRED = UIRemoteNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
static const UIRemoteNotificationType REMOTE_NOTIFICATION_TYPES_REQUIRED = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;

NSString *const kJCBadgeManagerBadgesKey        = @"badges";
NSString *const kJCBadgeManagerVoicemailsKey    = @"voicemails";
NSString *const kJCBadgeManagerV4VoicemailKey   = @"v4_voicemails";
NSString *const kJCBadgeManagerMissedCallsKey   = @"missedCalls";

@interface JCBadgeManager () <NSFetchedResultsControllerDelegate>
{
    JCBadges *_badges;
    JCBadges *_batchBadges;      // Used as a temp badges array during batch processing.
}

// Internal Properties
@property (nonatomic, readwrite) NSManagedObjectContext *context;
@property (nonatomic, readwrite) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite) JCBadges *badges;
@property (nonatomic, readwrite) NSUInteger v4_voicemails;
@property (nonatomic, readwrite) NSString *selectedLine;

@end

@implementation JCBadgeManager

-(instancetype)init
{
    self = [super init];
    if (self) {
        UIApplication *application = [UIApplication sharedApplication];
        if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            if (![self canSendNotifications]) {
                UIUserNotificationSettings* requestedSettings = [UIUserNotificationSettings settingsForTypes:USER_NOTIFICATION_TYPES_REQUIRED categories:nil];
                [application registerUserNotificationSettings:requestedSettings];
            }
        }else {
            [application registerForRemoteNotificationTypes:REMOTE_NOTIFICATION_TYPES_REQUIRED];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

+ (void)updateBadgesFromContext:(NSManagedObjectContext *)context
{
    JCBadgeManager *badgeManager = [JCBadgeManager sharedManager];
    badgeManager.context = context;
    badgeManager->_badges = nil;
    [badgeManager update];
}

+ (void)reset
{
    [[JCBadgeManager sharedManager] reset];
}

+ (void)setVoicemails:(NSUInteger)voicemails
{
    [JCBadgeManager sharedManager].v4_voicemails = voicemails;
}

+ (void)setSelectedLine:(NSString *)line
{
    JCBadgeManager *badgeManager = [JCBadgeManager sharedManager];
    badgeManager.selectedLine = line;
}


-(void)didReceiveMemoryNotification:(NSNotification *)notification
{
    _batchBadges = nil;
    self.badges = _badges;
    _badges = nil;
}

#pragma mark - Getters -

/**
 *  Returns the full all the recent events. Used for badging the app.
 */
- (NSUInteger)recentEvents
{
    NSString *line = self.selectedLine;
    NSDictionary *eventTypes = [self.badges eventTypesForKey:line];
    NSArray *keys = eventTypes.allKeys;
    int total = 0;
    for (NSString *key in keys){
        if ([key isEqualToString:kJCBadgeManagerV4VoicemailKey]){
            id object = [eventTypes objectForKey:key];
            if ([object isKindOfClass:[NSNumber class]]) {
                total += ((NSNumber *)object).integerValue;
            }
        }
        else {
            total += [self.badges countForEventType:key key:line];
        }
    }
    return total;
}

/**
 * Returns count of unread missed calls.
 */
- (NSUInteger)missedCalls
{
    return [self.badges countForEventType:kJCBadgeManagerMissedCallsKey key:_selectedLine];
}

/**
 * Returns count of unread voicemails.
 */
- (NSUInteger)voicemails
{
    NSUInteger total = [self v4_voicemails];
    total += [self.badges countForEventType:kJCBadgeManagerVoicemailsKey key:_selectedLine];
    return total;
}

#pragma mark - Delegate Handlers -

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    _batchBadges = self.badges.copy;
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [_batchBadges addRecentEvent:anObject];
            break;
        
        case NSFetchedResultsChangeUpdate:
            [_batchBadges processRecentEvent:anObject];
            
        case NSFetchedResultsChangeDelete:
            [_batchBadges removeRecentEvent:anObject];
            
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    self.badges = _batchBadges;
    _batchBadges = nil;
}

#pragma mark - Private -

#pragma mark Internal Properties

-(void)setBadges:(JCBadges *)badges
{
    [self willChangeContent];
    _badges = badges;
    NSDictionary *badgeData;
    if (badges) {
        badgeData = badges.badgeData;
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:badgeData forKey:kJCBadgeManagerBadgesKey];
    [userDefaults synchronize];
    [self didChangeContent];
}

- (JCBadges *)badges
{
    if (!_badges) {
        NSDictionary *badgeData = [[NSUserDefaults standardUserDefaults] objectForKey:kJCBadgeManagerBadgesKey];
        JCBadges *badges = [[JCBadges alloc] initWithBadgeData:badgeData];
        NSFetchedResultsController *resultsController = self.fetchedResultsController;
        if (resultsController) {
            __autoreleasing NSError *error;
            if([resultsController performFetch:&error]) {
                [badges processRecentEvents:resultsController.fetchedObjects];
            }
            self.badges = badges;
        } else {
            _badges = badges;
        }
    }
    return _badges;
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        
        if (!_context) {
            return nil;
        }
        
        NSFetchRequest *fetchRequest = [RecentEvent MR_requestAllSortedBy:NSStringFromSelector(@selector(date))
                                                                ascending:NO
                                                                inContext:_context];
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:_context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
        _fetchedResultsController.delegate = self;
    }
    return _fetchedResultsController;
}


-(void)setV4_voicemails:(NSUInteger)v4_voicemails
{
    NSMutableDictionary *eventTypes = [self.badges eventTypesForKey:_selectedLine];
    [eventTypes setObject:[NSNumber numberWithInteger:v4_voicemails] forKey:kJCBadgeManagerV4VoicemailKey];
    [self.badges setEventTypes:eventTypes key:_selectedLine];
    [self saveBadges];
}

- (NSUInteger)v4_voicemails
{
    NSUInteger total = 0;
    NSDictionary *eventTypes = [self.badges eventTypesForKey:_selectedLine];
    id object = [eventTypes objectForKey:kJCBadgeManagerV4VoicemailKey];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        total += ((NSNumber *)object).integerValue;
    }
    return total;
}

- (void)setSelectedLine:(NSString *)selectedLine
{
    [self willChangeContent];
    _selectedLine = selectedLine;
    [self didChangeContent];
}

#pragma mark Methods

// Checks the permissions to see if we can sent notifications, including badging.
- (BOOL)canSendNotifications;
{
    UIApplication *application = [UIApplication sharedApplication];
    if (![application respondsToSelector:@selector(currentUserNotificationSettings)])
        return true; // We actually just don't know if we can, no way to tell programmatically before iOS8
    
    UIUserNotificationSettings *notificationSettings = [application currentUserNotificationSettings];
    return (notificationSettings.types == USER_NOTIFICATION_TYPES_REQUIRED);
}

-(void)willChangeContent
{
    [self willChangeValueForKey:kJCBadgeManagerMissedCallsKey];
    [self willChangeValueForKey:kJCBadgeManagerVoicemailsKey];
}

-(void)didChangeContent
{
    [self didChangeValueForKey:kJCBadgeManagerMissedCallsKey];
    [self didChangeValueForKey:kJCBadgeManagerVoicemailsKey];
    [self update];
}

-(void)reset
{
    self.badges = nil;
}

-(void)update
{
    NSUInteger recentEvents = self.recentEvents;
    if ([self canSendNotifications] && recentEvents != [UIApplication sharedApplication].applicationIconBadgeNumber) {
        [UIApplication sharedApplication].applicationIconBadgeNumber = recentEvents;
    }
}

-(void)saveBadges
{
    if (_badges) {
        self.badges = _badges;
    }
}

@end
