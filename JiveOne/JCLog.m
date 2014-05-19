#import "JCLog.h"

static int gJCLogLevel = JCLogLevelDebug;

void JCLogLevelSetConfiguration(JCLogLevel level) {
    gJCLogLevel = level;
}

JCLogLevel JCLogLevelGetConfiguration(void) {
    return gJCLogLevel;
}