//
//  JCBadgeManager.m
//  JiveOne
//
//  Created by Robert Barclay on 10/31/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCBadgeManager.h"
#import "LoggerClient.h"

#import "RecentEvent.h"
#import "MissedCall.h"
#import "Voicemail.h"
#import "Conversation.h"

#import "JCBadgeManagerBatchOperation.h"

static const UIUserNotificationType USER_NOTIFICATION_TYPES_REQUIRED = UIRemoteNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
static const UIRemoteNotificationType REMOTE_NOTIFICATION_TYPES_REQUIRED = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;

NSString *const kJCBadgeManagerBadgesKey        = @"badges";
NSString *const kJCBadgeManagerRecentEventsKey  = @"recentEvents";
NSString *const kJCBadgeManagerVoicemailsKey    = @"voicemails";
NSString *const kJCBadgeManagerV4VoicemailKey   = @"v4_voicemails";
NSString *const kJCBadgeManagerMissedCallsKey   = @"missedCalls";
NSString *const kJCBadgeManagerConversationsKey = @"conversations";

NSString *const kJCBadgeManagerInsertedIdentifierNotification = @"insertedIdentifier";
NSString *const kJCBadgeManagerDeletedIdentifierNotification = @"deletedIdentifier";
NSString *const kJCBadgeManagerIdentifierKey = @"identifierKey";
NSString *const kJCBadgeManagerBadgeKey = @"badgeKey";

@interface JCBadgeManager ()
{
    NSMutableDictionary *_batchBadges;
    NSOperationQueue *_operationQueue;
}

@property (nonatomic, readonly) NSString *currentLineIdentifier;

@end

@implementation JCBadgeManager

-(instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super init];
    if (self) {
        _managedObjectContext = managedObjectContext;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextUpdated:) name:NSManagedObjectContextDidSaveNotification object:_managedObjectContext];
        [self addObserver:self forKeyPath:kJCBadgeManagerBadgesKey options:NSKeyValueObservingOptionNew context:nil];
        
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

-(void)initialize
{
    UIApplication *application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        if (![self canSendNotifications])
        {
            UIUserNotificationSettings* requestedSettings = [UIUserNotificationSettings settingsForTypes:USER_NOTIFICATION_TYPES_REQUIRED categories:nil];
            [application registerUserNotificationSettings:requestedSettings];
        }
    }
    else
    {
        [application registerForRemoteNotificationTypes:REMOTE_NOTIFICATION_TYPES_REQUIRED];
    }
    [self update];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kJCBadgeManagerBadgesKey]) {
        [self update];
    }
}

-(void)update
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSUInteger recentEvents = self.recentEvents;
        if (self.canSendNotifications && recentEvents != [UIApplication sharedApplication].applicationIconBadgeNumber)
        {
//            NSLog(@"recentEvents: %lu", (unsigned long)recentEvents);
            [UIApplication sharedApplication].applicationIconBadgeNumber = recentEvents;
        }
    });
}

-(void)startBackgroundUpdates
{
//    NSString *lineIdentifier = self.currentLineIdentifier;
//    NSMutableDictionary *lineIdentifiers = [self identifiersForLine:lineIdentifier];
//    NSArray *keys = [lineIdentifiers allKeys];
//    for (NSString *key in keys)
//    {
//        NSMutableDictionary *identifiers = [self identifiersForKey:key line:lineIdentifier];
//        NSArray *identifierKeys = [identifiers allKeys];
//        for (NSString *identifier in identifierKeys)
//        {
//            [self setIdentifier:identifier forKey:key line:lineIdentifier displayed:YES];
//        }
//    }
}

-(NSUInteger)endBackgroundUpdates
{
    // TODO: enumberate through all the badges, identifieying badges that have not been flagged as displayed, get
    // managed objects for the badge, and generate a local notification for it, flagging it as displayed.
    return 0;
}

// Clears out the badges in the badges array.

-(void)reset
{
    [self willChangeValueForKey:kJCBadgeManagerMissedCallsKey];
    [self willChangeValueForKey:kJCBadgeManagerVoicemailsKey];
    [self willChangeValueForKey:kJCBadgeManagerConversationsKey];
    
    self.badges = nil;
    
    [self didChangeValueForKey:kJCBadgeManagerMissedCallsKey];
    [self didChangeValueForKey:kJCBadgeManagerVoicemailsKey];
    [self didChangeValueForKey:kJCBadgeManagerConversationsKey];
}

#pragma mark - Setters -

-(void)setBadges:(NSMutableDictionary *)badges
{
    [self willChangeValueForKey:kJCBadgeManagerMissedCallsKey];
    [self willChangeValueForKey:kJCBadgeManagerVoicemailsKey];
    [self willChangeValueForKey:kJCBadgeManagerConversationsKey];
    [self willChangeValueForKey:kJCBadgeManagerBadgesKey];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:badges forKey:kJCBadgeManagerBadgesKey];
    [userDefaults synchronize];
    [self didChangeValueForKey:kJCBadgeManagerBadgesKey];
    
    [self didChangeValueForKey:kJCBadgeManagerMissedCallsKey];
    [self didChangeValueForKey:kJCBadgeManagerVoicemailsKey];
    [self didChangeValueForKey:kJCBadgeManagerConversationsKey];
}

-(void)setVoicemails:(NSUInteger)voicemails
{
    [self willChangeValueForKey:kJCBadgeManagerVoicemailsKey];
    NSString *line = [JCAuthenticationManager sharedInstance].line.jrn;
    NSMutableDictionary *eventTypes = [self eventTypesForLine:line];
    [eventTypes setObject:[NSNumber numberWithInteger:voicemails] forKey:kJCBadgeManagerV4VoicemailKey];
    [self setEventTypes:eventTypes line:line];
    [self didChangeValueForKey:kJCBadgeManagerVoicemailsKey];
}

#pragma mark - Getters -

-(NSMutableDictionary *)badges
{
    return [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kJCBadgeManagerBadgesKey]];
}

// Checks the permissions to see if we can sent notifications, including badging.
- (BOOL)canSendNotifications;
{
    UIApplication *application = [UIApplication sharedApplication];
    if (![application respondsToSelector:@selector(currentUserNotificationSettings)])
        return true; // We actually just don't know if we can, no way to tell programmatically before iOS8
    
    UIUserNotificationSettings *notificationSettings = [application currentUserNotificationSettings];
    return (notificationSettings.types == USER_NOTIFICATION_TYPES_REQUIRED);
}

- (NSUInteger)recentEvents
{
    NSString *line = [JCAuthenticationManager sharedInstance].line.jrn;
    NSDictionary *eventTypes = [self eventTypesForLine:line];
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
            total += [self countForEventType:key];
        }
    }
    return total;
}

- (NSUInteger)voicemails
{
    NSString *line = [JCAuthenticationManager sharedInstance].line.jrn;
    NSUInteger total = 0;
    NSDictionary *eventTypes = [self eventTypesForLine:line];
    id object = [eventTypes objectForKey:kJCBadgeManagerV4VoicemailKey];
    if (object && [object isKindOfClass:[NSNumber class]]) {
        total += ((NSNumber *)object).integerValue;
    }
    
    total += [self countForEventType:kJCBadgeManagerVoicemailsKey];
    return total;
}

- (NSUInteger)missedCalls
{
    return [self countForEventType:kJCBadgeManagerMissedCallsKey];
}

- (NSUInteger)conversations
{
    return [self countForEventType:kJCBadgeManagerConversationsKey];
}

#pragma mark - Notification Handlers -

-(void)managedObjectContextUpdated:(NSNotification *)notification
{
    __block NSDictionary *userInfo = notification.userInfo;
    __unsafe_unretained NSOperationQueue *weakOperationQueue = _operationQueue;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakOperationQueue addOperation:[[JCBadgeManagerBatchOperation alloc] initWithDictionaryUpdate:userInfo]];
    });
}

#pragma mark - Private -

/**
 * Gets the badge count of a badge category key.
 */
-(NSUInteger)countForEventType:(NSString *)eventType
{
    NSString *line = [JCAuthenticationManager sharedInstance].line.jrn;
    NSDictionary *events = [self eventsForEventType:eventType line:line];
    return events.allKeys.count;
}

/**
 * Returns a dictionary of badge identifiers for a given key from the badges dictionary in the user default. If non have
 * been set, it should return nil, otherwise, it should return a dictionary of identifiers, where the identifier is the
 * key, and a bool is the value.
 */
-(NSMutableDictionary *)eventsForEventType:(NSString *)type line:(NSString *)line
{
    NSMutableDictionary *eventTypes = [self eventTypesForLine:line];
    id object = [eventTypes objectForKey:type];
    if ([object isKindOfClass:[NSDictionary class]]) {
        return [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)object];
    }
    return [NSMutableDictionary dictionary];
}

-(NSMutableDictionary *)eventTypesForLine:(NSString *)line
{
    id object = [self.badges objectForKey:line];
    if ([object isKindOfClass:[NSDictionary class]]) {
        return [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)object];
    }
    return [NSMutableDictionary dictionary];
}

-(void)setEventTypes:(NSDictionary *)eventTypes line:(NSString *)line
{
    NSMutableDictionary *badges = self.badges;
    [badges setObject:eventTypes forKey:line];
    self.badges = badges;
}


/**
 * Sets the the badge identifiers for a given key.
 *
 * This method does not merge current identifers, but rather replaces them. If you are updating, You should get the 
 * identifiers, add them, the set them.
 */
//-(void)setIdentifiers:(NSDictionary *)identifiers forKey:(NSString *)key line:(NSString *)line
//{
//    [self willChangeValueForKey:key];
//    NSMutableDictionary *lineIdentifiers = [self identifiersForLine:line];
//    [lineIdentifiers setObject:identifiers forKey:key];
//    [self setIdentifiers:lineIdentifiers line:line];
//    [self didChangeValueForKey:key];
//}
//


/*
- (void)setNotification:(NSInteger)voicemailCount conversation:(NSInteger)conversationCount {
    LOG_Info();
    
    //if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)  {
    
    NSMutableDictionary *_badges = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"badges"]];
    
    
    [_badges enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSRange rangeConversation = [key rangeOfString:@"conversations"];
        NSRange rangeRooms = [key rangeOfString:@"permanentrooms"];
        if (rangeConversation.location != NSNotFound || rangeRooms.location != NSNotFound) {
            NSMutableDictionary *convCopy = nil;
            if ([_badges[key] isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary *conversations = [_badges[key] mutableCopy];
                if (conversations) {
                    convCopy = [[conversations copy] mutableCopy];
                    for (NSString *entry in conversations) {
                        NSNumber *shown = conversations[entry];
                        if (![shown boolValue]) {
                            
                            ConversationEntry *lastEntry = [ConversationEntry MR_findFirstByAttribute:@"entryId" withValue:entry];
                            PersonEntities *person = [PersonEntities MR_findFirstByAttribute:@"entityId" withValue:lastEntry.entityId];
                            NSString *alertMessage = [NSString stringWithFormat:@"%@: \"%@\"", person.firstName, lastEntry.message[@"raw"]];
                            
                            [self showLocalNotificationWithType:@"conversation" alertMessage:alertMessage];
                            [convCopy setObject:[NSNumber numberWithBool:YES] forKey:entry];
                            
                            
                        }
                    }
                    [_badges setObject:convCopy forKey:key];
                }
            }
            
        }
        
        NSRange rangeVoicemail = [key rangeOfString:@"jrn"];
        if (rangeVoicemail.location != NSNotFound ) {
            NSNumber *notified = _badges[key];
            if (![notified boolValue]) {
                notified = [NSNumber numberWithBool:YES];
                Voicemail *lastEntry = [Voicemail MR_findFirstByAttribute:@"jrn" withValue:key];
                if (lastEntry) {
                    NSString *alertMessage = lastEntry.name ? [NSString stringWithFormat:@"New voicemail from %@", lastEntry.number]  : @"Unknown";
                    [self showLocalNotificationWithType:@"voicemail" alertMessage:alertMessage];
                }
            }
            _badges[key] = notified;
            //[[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
            //[[NSUserDefaults standardUserDefaults] synchronize];
        }
        
    }];
    
    [[NSUserDefaults standardUserDefaults] setObject:[_badges copy] forKey:@"badges"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}*/

/*- (void)showLocalNotificationWithType:(NSString *)alertType alertMessage:(NSString *)alertMessage
{
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = alertMessage;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}*/

@end



@implementation JCBadgeManager (Singleton)

+(JCBadgeManager *)sharedManager
{
    // Makes the startup of this singleton thread safe.
    static JCBadgeManager *badgeManager = nil;
    static dispatch_once_t pred;        // Lock
    dispatch_once(&pred, ^{             // This code is called at most once per app
        badgeManager = [[JCBadgeManager alloc] initWithManagedObjectContext:[NSManagedObjectContext MR_rootSavingContext]];
    });
    
    return badgeManager;
}

+ (id)copyWithZone:(NSZone *)zone
{
    return self;
}

+ (void)update
{
    [[JCBadgeManager sharedManager] update];
}

+ (void)reset
{
    [[JCBadgeManager sharedManager] reset];
}

@end
