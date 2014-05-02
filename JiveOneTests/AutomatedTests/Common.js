
function test(title, f, options) {
  if (options == null) {
    options = {
      logTree: true
    };
  }
  target = UIATarget.localTarget();
  application = target.frontMostApp();
  UIALogger.logStart(title);
  try {
    f(target, application);
    UIALogger.logPass(title);
  }
  catch (e) {
    UIALogger.logError(e);
    if (options.logTree) target.logElementTree();
    UIALogger.logFail(title);
  }
};

function assertEquals(expected, received, message) {
  if (received != expected) {
    if (! message) message = "Expected " + expected + " but received " + received;
    throw message;
  }
}
  
function assertTrue(expression, message) {
  if (! expression) {
    if (! message) message = "Assertion failed";
    throw message;
  }
}
  
function assertFalse(expression, message) {
  assertTrue(! expression, message);
}
  
function assertNotNull(thingie, message) {
  if (thingie == null || thingie.toString() == "[object UIAElementNil]") {
    if (message == null) message = "Expected not null object";
    throw message;
  }
}