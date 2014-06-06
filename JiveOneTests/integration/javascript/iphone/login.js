#import "../../../../../Pods/tuneup_js/tuneup.js"

test("Login Test", function(target, app, log){
	var currentWindow = app.mainWindow();

	//login
	currentWindow.textFields()["emailTextField"].setValue("jivetesting10@gmail.com");
	currentWindow.secureTextFields()["passwordTextField"].setValue("testing12");
	app.keyboard().elements()["Go"].tap();

	//wait for login
	UIATarget.localTarget().pushTimeout(200);
	currentWindow.navigationBar().name()["People"];
	UIATarget.localTarget().popTimeout();
	currentWindow = app.mainWindow();

	//capture navigation bar name
	var title = currentWindow.navigationBar().name()

	//get count of contacts
	var contactsList = currentWindow.tableViews()[0];
	var count = contactsList.cells().length;

	assertEquals("People", title, "Should have loaded 'People' tab");
	UIALogger.logDebug("the count was " + count);
	assertTrue(count>0, "contacts should have loaded");
});

