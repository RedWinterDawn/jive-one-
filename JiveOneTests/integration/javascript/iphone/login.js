#import "../Common.js"


//alerts
UIATarget.onAlert = function onAlert(alert) {
	delay(1);
	var title = alert.name();
	UIALogger.logWarning("Alert where title '" + title + "' encountered.");
	if (title == "Authentication Error" || title == "Invalid Parameters") {
		logDebug("entering title if");
		alert.buttons()["OK"].tap();
		delay(1);
		return true;  //alert handled, so bypass the default handler
	}else{
		logDebug("entering title else");
		// return false to use the default handler
		delay(1);
		fail("Alert view title was unexpected: '" + title + "'");
		return false;		
	}
	
}


test("Login Test", function(target, app){
	
	logoutIfNeeded(app);
	
	// Select e-mail address box on login screen and Confirm that keyboard is displayed
	app.mainWindow().textFields()["emailTextField"].tap();
	delay(2);
	assertTrue(app.mainWindow().textFields()["emailTextField"].hasKeyboardFocus());
	logDebug(target.frontMostApp().keyboard().keyboardType());
	// assertEquals("KEYBOARD_TYPE_ALPHA", app.keyboard().keyboardType(), "Keyboard should have been KEYBOARD_TYPE_ALPHA");
	
	//TODO: Confirm that both username and password boxes are visible and located where they should be.
	
	
	// Enter an invalid username
	target.frontMostApp().mainWindow().textFields()["emailTextField"].setValue("ljksdfa");
	// Select Password box
	// Enter random password text
	app.mainWindow().secureTextFields()["passwordTextField"].setValue("ljksdfa");
	// Click 'Go' button
	app.keyboard().elements()["Go"].tap();
	// Confirm presence of “Authentication Error” dialog
	// Click 'OK'
		//handled in function above
		
	// Select e-mail address box on login screen
	// Enter a valid username
	logDebug("after alert view");
	app.mainWindow().textFields()["emailTextField"].setValue("jivetesting12@gmail.com");
	// Select Password box
	// Enter an invalid password
	app.mainWindow().secureTextFields()["passwordTextField"].setValue("ljksdfa");
	// Click 'Go' button
	app.keyboard().elements()["Go"].tap();
	// Confirm presence of "Authentication Error" dialog
	// Click OK
		//handled in function above
	
	
	// Select Password box
	// Clear box
	app.mainWindow().secureTextFields()["passwordTextField"].clear();
	// Click 'Go' button
	app.keyboard().elements()["Go"].tap();
	// Confirm presence of 'Invalid parameters' error dialog
	// Click OK
		//handled in function above	
	
	// Select Password box	
	// Enter a valid password, consisting of mixed-case alpha, numeric and special chars.  This will exercise the alpha, shift, and #+= screens and buttons. and Click ‘Go’ button
	defaultLogin(app);
		
	
	// Confirm landing page is the ‘People’ user list
	var title =  app.mainWindow().navigationBar().name()	
	assertEquals("People", title, "Should have loaded 'People' tab");
	var count = app.mainWindow().tableViews()[0].cells().length;
	logDebug("the count was " +  count);
	assertTrue(count>0, "contacts should have loaded");
	
});

