//Login test 
//Created by Pete Leonard
#import "../Common.js"

var target = UIATarget.localTarget();
var app = target.frontMostApp();
var didLogin = "";
target.pushTimeout(1);
if (app.mainWindow().textFields()["emailTextField"].isValid()) {
	UIALogger.logMessage("Your in the correct state of the app for these tests");
	} 
	else {
		UIALogger.logMessage("Your tests would normaly fail because you are already logged in but no worries Pete is the Best and will log out for you");
		logout();
		};

incorrectLogin();
dismissWithLittleX();
incorrectPassword();
login();

//###############################
// incorrect User Name Login Test
//###############################
function incorrectLogin() {	
	var testName = "incorrectLogin";
	testsSetup(testName);
	//tap on the email feild and enter user name
	UIATarget.localTarget().frontMostApp().mainWindow().textFields()["emailTextField"].textFields()["emailTextField"].tap();
	target.pushTimeout();
	//clear the text feild just in case 
	UIATarget.localTarget().frontMostApp().mainWindow().textFields()["emailTextField"].textFields()["emailTextField"].setValue("");

	target.frontMostApp().keyboard().typeString("stpdFatTumbsCnTIpe.onFissKeyboorwd");
	target.frontMostApp().mainWindow().secureTextFields()["passwordTextField"].secureTextFields()["passwordTextField"].tap();
	target.frontMostApp().keyboard().typeString("testing12");
	target.pushTimeout();
	var failLogin = target.frontMostApp().mainWindow().isValid();
	verifyTest(testName, failLogin, failLogin);
	};

//###############################
// incorrect User Name Dismiss with little x Test
//###############################
function dismissWithLittleX() {
	testName = "Dismiss with little x"
	testsSetup(testName);
	UIATarget.localTarget().frontMostApp().mainWindow().textFields()["emailTextField"].textFields()["emailTextField"].tap();
	target.pushTimeout();
	UIATarget.localTarget().frontMostApp().mainWindow().textFields()["emailTextField"].textFields()["emailTextField"].setValue("");
	target.frontMostApp().keyboard().typeString("stillCantType");
	target.pushTimeout();
	target.frontMostApp().mainWindow().textFields()["emailTextField"].buttons()["Clear text"].tap();
	target.frontMostApp().mainWindow().secureTextFields()["passwordTextField"].secureTextFields()["passwordTextField"].tap();
	target.frontMostApp().keyboard().typeString("testing12");
	target.pushTimeout();
	target.frontMostApp().mainWindow().secureTextFields()["passwordTextField"].buttons()["Clear text"].tap();
	target.delay(2);
	UIALogger.logMessage(target.frontMostApp().mainWindow().secureTextFields()["passwordTextField"].value());
	target.logElementTree();
	failLogin = target.frontMostApp().mainWindow().secureTextFields()["passwordTextField"].value();
	exspected = "Password";
	verifyTest(testName, failLogin, exspected);
	};

//###############################
// incorrect Password Login Test
//###############################
function incorrectPassword() {
	testName = "incorrectPassword";
	testsSetup(testName);
	//A Test for making sure we get the correct reaction to a inccorect password attempt
	UIATarget.localTarget().frontMostApp().mainWindow().textFields()["emailTextField"].textFields()["emailTextField"].setValue("");
	target.frontMostApp().keyboard().typeString("jivetesting12@gmail.com");

	target.frontMostApp().mainWindow().secureTextFields()["passwordTextField"].secureTextFields()["passwordTextField"].tap();

	target.frontMostApp().keyboard().typeString("EduardosSecretPassword");
	target.frontMostApp().keyboard().typeString("\n");
	target.pushTimeout();
	failLogin = target.frontMostApp().mainWindow().isValid();
	valid = true;
	verifyTest(testName,failLogin,valid);
	};

//##########################
// correct Login Test
//##########################
function login() {
	testName = "login";
	testsSetup(testName);
	UIATarget.localTarget().frontMostApp().mainWindow().textFields()["emailTextField"].textFields()["emailTextField"].setValue("");
	target.frontMostApp().keyboard().typeString("jivetesting12@gmail.com");
	target.frontMostApp().keyboard().typeString("\n");
	target.pushTimeout();
	//tap on password field contents and enter password --secure text fields clear current contents by default
	target.frontMostApp().mainWindow().secureTextFields()["passwordTextField"].secureTextFields()["passwordTextField"].tap();
	target.frontMostApp().keyboard().typeString("testing12");
	//hit enter
	target.frontMostApp().keyboard().typeString("\n");
	target.pushTimeout();
	//capture screen
	target.captureScreenWithName("ScreenState");
	target.delay(2);
	//Test for the navBar to prove we made it in
	var madeItInApp = target.frontMostApp().tabBar().buttons()["People"].isValid()
	UIALogger.logMessage(target.frontMostApp().tabBar().buttons()["People"].isValid());
	
	//var madeItInApp = target.frontMostApp().tabBar().
	target.delay(5);
	verifyTest(testName,madeItInApp,false);
	};


//################################
//People View
//################################
function peopleView () {
	testName = "PeopleView";
	testsSetup(testName);
	target.frontMostApp().tabBar().buttons()["People"].tap();
	
	//Select the search bar, Find JiveTesting13, Select -> Profile, Select favorite, Hit Navagation button to go back, Select little x,Select random spot to dismiss search
	target.frontMostApp().mainWindow().searchBars()[0].searchBars()[0].tap();
	target.frontMostApp().keyboard().typeString("13");
	target.tap({x:299.50, y:45.50});
	
	//target.frontMostApp().mainWindow().searchBars()[0].searchBars()[0].tap();
	target.frontMostApp().keyboard().typeString("13");
	target.frontMostApp().mainWindow().tableViews()["Search results"].visibleCells()["Jive Testing 13"].tap();
	target.pushTimeout(9);
	target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Jive Testing 13"].buttons()["★"].tap();
	target.frontMostApp().navigationBar().leftButton().tap();
	madeItInApp = false
	verifyTest(testName,madeItInApp,false);
};
	 
	 
//###############################
//Logout Test
//###############################	 
function logout () { 
	testName = "logout";	
	UIALogger.logStart(testName);
	target.delay(1);
	target.logElementTree();
	// Navagate to more view
	target.frontMostApp().tabBar().buttons()["More"].tap();
	target.delay(1);
	target.captureScreenWithName("The More Menu");

	//logout to put the app back in the state we started in

	target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Sign Out"].tap();

	target.delay(2);
	UIALogger.logMessage(target.frontMostApp());
	var madeItOutApp = UIATarget.localTarget().frontMostApp().mainWindow().textFields()["emailTextField"].textFields()["emailTextField"]
	target.delay(2);
	test(testName,madeItOutApp,false);
	 
	};



//Handles the alert pop ups
UIATarget.onAlert = function onAlert(alert) {
	var title = alert.name();
	UIALogger.logWarning("Alert with title " + title+ "'encountered!");
	if (title == "This error") {
		alert.buttons() ["Ignore"].tap();
		return true;
	}
	UIALogger.logMessage("Dissmissed an Alert like a boss");
	return false;
}



function test(testName,checkAgainstWeitherThisIsTrue,didItWork) {
	var identifyingNameThingee = testName;
	var theSateOfThings = didItWork;
	var verifyWithDiss = checkAgainstWeitherThisIsTrue;
	if (verifyWithDiss) {
		theStateOfThings = true;
		UIALogger.logPass("The " + identifyingNameThingee + " Test passed good job.");
		return theStateOfThings;
		}
	else {
		theStateOfThings = false;
		UIALogger.logFail("Well shucks, the ***" + identifyingNameThingee + "*** Test failed, So you should go fixit, your verify was a: " + verifyWithDiss);
		return theStateOfThings;
		};
	};




function loginIfNeeded(app) {

        UIALogger.logDebug("test if we are logged out...");
        if (app.mainWindow().textFields()[0].name() == "emailTextField") {
           defaultLogin(app);
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

function defaultLogin(app) {
    login(app, "jivetesting12@gmail.com", "testing12");
}

//function login(app, user, password) {
//    var currentWindow = app.mainWindow();
//    logDebug("Logging in as " + user);
    
    //login
//    currentWindow.textFields()["emailTextField"].setValue(user);
//    currentWindow.secureTextFields()["passwordTextField"].setValue(password);
//    app.keyboard().elements()["Go"].tap();
    
    //wait for login
//    UIATarget.localTarget().pushTimeout(10);
//    currentWindow.navigationBar().name()["People"];
//    UIATarget.localTarget().popTimeout();
    
//    UIATarget.localTarget().delay(2);
//};


function testsSetup(testName) {
	UIALogger.logStart(testName);
	target.logElementTree();
	target.pushTimeout();
	};

//###########################################################
//Pass your check element and what you exspect from it.
//###########################################################
function verifyTest(testName, checkElement, verifyWithDiss) {
	var test = testName;
	if (verifyWithDiss === checkElement) {
		UIALogger.logPass("The " + test + " test passed good job."+checkElement + verifyWithDiss);
		return true
		}
	else {
		UIALogger.logFail("Well shucks, the ***" + test + "*** Test failed, So you should go fixit, It was "+checkElement+" But we expected to get -" + verifyWithDiss);
		return false
		}
	};
