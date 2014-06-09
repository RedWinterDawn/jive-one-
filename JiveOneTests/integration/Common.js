// 
// function test(title, f, options) {
//     if (options == null) {
//         options = {
//             logTree: true
//         };
//     }
//     target = UIATarget.localTarget();
//     application = target.frontMostApp();
//     UIALogger.logStart(title);
// 
//     try {
//         //login check
//         loginCheck(application);
// 
//         f(target, application);
//         UIALogger.logPass(title);
//     } catch (e) {
//         UIALogger.logError(e);
//         if (options.logTree) target.logElementTree();
//         UIALogger.logFail(title);
//     }
// };

function loginIfNeeded(app) {

        UIALogger.logDebug("test if we are logged out...");
        if (app.mainWindow().textFields()[0].name() == "emailTextField") {
           login(app);
        }else{
          UIALogger.logDebug("Already logged in.");  
        }
}

function logoutIfNeeded(app) {
    UIALogger.logDebug("test if we are logged out...");
    if (app.mainWindow().textFields()[0].name() == "emailTextField") {
        //do nothing
        UIALogger.logDebug("Already logged out.");  
    }else{
      logout(app)
    }
}

function login(app) {
    var currentWindow = app.mainWindow();
    
    //login
    currentWindow.textFields()["emailTextField"].setValue("jivetesting21@gmail.com");
    currentWindow.secureTextFields()["passwordTextField"].setValue("testing21");
    app.keyboard().elements()["Go"].tap();
    
    //wait for login
    UIATarget.localTarget().pushTimeout(200);
    currentWindow.navigationBar().name()["People"];
    UIATarget.localTarget().popTimeout();
    
    UIATarget.localTarget().delay(2);
}

function logout(app) {
    app.mainWindow().tabBar().buttons()[3].tap();
    target.logElementTree();
    
    var recipient = app.mainWindow().tableViews()[0].cells()[0].name();
    UIALogger.logDebug("logged in as:" + recipient);
    if(recipient.contains("jivetesting21@gmail.com"))
    {
        recipient = "jivetesting11@gmail.com";
    }else{
        recipient = "jivetesting21@gmail.com";
    }    
    
    scrollDown(200);
    var logoutButton = app.mainWindow().tableViews()[0].cells()["Sign Out"];
    logDebug(logoutButton.name());
    logoutButton.waitUntilVisible(10);
    UIATarget.localTarget().delay(2);
    app.mainWindow().tableViews()[0].cells()["Sign Out"].tap();
    UIALogger.logDebug("will log in as: "+ recipient);

}

function logDebug(s){
    UIALogger.logDebug(s)
}

function scrollDown(pixels){

    var y1 = 400;
    var y2 = y1-pixels;

    UIATarget.localTarget().flickFromTo({x:160, y:y1}, {x:160, y:y2});
}

// function assertEquals(expected, received, message) {
//     if (received != expected) {
//         if (!message) message = "Expected " + expected + " but received " + received;
//         throw message;
//     }
// }
// 
// function assertTrue(expression, message) {
//     if (!expression) {
//         if (!message) message = "Assertion failed";
//         throw message;
//     }
// }
// 
// function assertFalse(expression, message) {
//     assertTrue(!expression, message);
// }
// 
// function assertNotNull(thingie, message) {
//     if (thingie == null || thingie.toString() == "[object UIAElementNil]") {
//         if (message == null) message = "Expected not null object";
//         throw message;
//     }
// }

String.prototype.contains = function(it) { return this.indexOf(it) != -1; };