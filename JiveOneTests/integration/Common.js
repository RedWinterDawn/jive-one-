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

function loginCheck(app) {

        UIALogger.logDebug("test if we are logged out...");
        if (app.mainWindow().textFields()[0].name() == "emailTextField") {
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
        }else{
          UIALogger.logDebug("Not logged out");  
        }
        // UIALogger.logDebug("end if");
 

}

function logout(app) {
    
    
}

function logDebug(s){
    UIALogger.logDebug(s)
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