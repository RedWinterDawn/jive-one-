//
//  JCLog.h
//  Jive
//
//  Created by Aneil Mallavarapu on 8/26/13.
//  Copyright (c) 2013 Jive Communications. All rights reserved.
//

#ifndef Jive_JCLog_h
#define Jive_JCLog_h
typedef enum enumJCLogLevel {
    JCLogLevelOff = 0,
    
    JCLogLevelCritical,              // critical situation
    JCLogLevelError,                 // error situation
    JCLogLevelInfo,                  // informational message
    JCLogLevelDebug,                 // coarse-grained debugging information
    
    _JCLogLevelCount,
    _JCLogLevelFirst = 0,
//    _JCLogLevelLast  = _RKlcl_level_t_count-1
} JCLogLevel;

void JCLogLevelSetConfiguration(JCLogLevel level);
JCLogLevel JCLogLevelGetConfiguration();

#import "LoggerClient.h"
#import "LoggerCommon.h"

#if !defined CONFIGURATION_Release
#define JCLogging 1
#define JCLog(fmt, ...) LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @"jiveclient", 0, fmt, ##__VA_ARGS__); \
NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

#define JCLog_() LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @"jiveclient", 0, @"(trace)"); \
NSLog(@"%s [Line %d] ", __PRETTY_FUNCTION__, __LINE__);

#define JCLogLevel(level, fmt, ...) LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @"jiveclient", level, fmt, ##__VA_ARGS__); \
NSLog(@"%s [Line %d] ", __PRETTY_FUNCTION__, __LINE__);

#define JCLogLevel_(level) if (JCLogLevelGetConfiguration()>=level) { LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @"jiveclient", level, @"(trace)"); NSLog(@"%s [Line %d] ", __PRETTY_FUNCTION__, __LINE__); }

#define JCLogImage(width,height,data) LogImageDataF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @"jiveclient", 0, width, height, data); \
NSLog(@"%s [Line %d] ", __PRETTY_FUNCTION__, __LINE__); 


#define JCLogCritical(fmt, ...) JCLogLevel(JCLogLevelCritical,fmt, ##__VA_ARGS__);
#define JCLogError(fmt, ...) JCLogLevel(JCLogLevelError,fmt, ##__VA_ARGS__);
#define JCLogInfo(fmt, ...) JCLogLevel(JCLogLevelInfo,fmt, ##__VA_ARGS__);
#define JCLogDebug(fmt, ...) JCLogLevel(JCLogLevelDebug,fmt, ##__VA_ARGS__);

#define JCLogCritical_() JCLogLevel_(JCLogLevelCritical);
#define JCLogError_() JCLogLevel_(JCLogLevelError);
#define JCLogInfo_() JCLogLevel_(JCLogLevelInfo);
#define JCLogDebug_() JCLogLevel_(JCLogLevelDebug);
//#define JCLogCritical(fmt, ...) if (JCLogLevelGetConfiguration()>=JCLogLevelCritical) { LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @"jiveclient", JCLogLevelCritical, fmt, ##__VA_ARGS__); NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); }

//#define JCLogInfo(fmt, ...) if (JCLogLevelGetConfiguration()>=JCLogLevelInfo) { LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @"jiveclient", JCLogLevelInfo, fmt, ##__VA_ARGS__); NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); }
//
//#define JCLogDebug(fmt, ...) if (JCLogLevelGetConfiguration()>=JCLogLevelDebug) { LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @"jiveclient", JCLogLevelDebug, fmt, ##__VA_ARGS__); NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); }
//
//#define JCLogCritical_() if (JCLogLevelGetConfiguration()>=JCLogLevelCritical) { LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @"jiveclient", JCLogLevelCritical, @"(trace)"); NSLog(@"[Line %d] ", __PRETTY_FUNCTION__, __LINE__); }
//
//#define JCLogError_() if (JCLogLevelGetConfiguration()>=JCLogLevelError) { LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @"jiveclient", JCLogLevelError, @"(trace)"); NSLog(@"[Line %d] ", __PRETTY_FUNCTION__, __LINE__); }
//
//#define JCLogInfo_() if (JCLogLevelGetConfiguration()>=JCLogLevelInfo) { LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @"jiveclient", JCLogLevelInfo, @"(trace)"); NSLog(@"[Line %d] ", __PRETTY_FUNCTION__, __LINE__); }
//
//#define JCLogDebug_() if (JCLogLevelGetConfiguration()>=JCLogLevelDebug) { LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @"jiveclient", JCLogLevelDebug, @"(trace)"); NSLog(@"[Line %d] ", __PRETTY_FUNCTION__, __LINE__); }

#define JCAssert(condition, fmt, ...) NSAssert(condition, ({ JCLogCritical(fmt, ##__VA_ARGS__); fmt; }), ##__VA_ARGS__);
#else
#define JCLogging 0
#define JCLog(...) do{}while(0);
#define JCLog_() do{}while(0);
#define JCLogLevel(...) do{}while(0);
#define JCLogLevel_(...) do{}while(0);
#define JCLogImage(...) do{}while(0);

#define JCLogCritical(...) if (JCLogLevelGetConfiguration()>=JCLogLevelCritical) { LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @"jiveclient", JCLogLevelCritical, @"(trace)"); NSLog(@"%s [Line %d] ", __PRETTY_FUNCTION__, __LINE__); }
#define JCLogError(...) do{}while(0);
#define JCLogInfo(...) do{}while(0);
#define JCLogDebug(...) do{}while(0);

#define JCLogCritical_() do{}while(0);
#define JCLogError_() do{}while(0);
#define JCLogInfo_() do{}while(0);
#define JCLogDebug_() do{}while(0);
#define JCAssert(condition, fmt, ...) JCLogCritical(fmt, ##__VA_ARGS__);
#endif

#endif
