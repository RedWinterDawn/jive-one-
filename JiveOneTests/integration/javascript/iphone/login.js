#import "../Common.js"

test("Login Test", function(target, app){
	
	logoutIfNeeded(app);
	
	//TODO{
	// Select e-mail address box on login screen
	// Confirm that keyboard is displayed, and both username and password boxes are visible and located where they should be.
	
	// Enter an invalid username
	// Select Password box
	// Enter random password text
	// Click 'Go' button
	// Confirm presence of “Authentication Error” dialog
	// Click 'OK'
	// Select e-mail address box on login screen
	// Enter a valid username
	// Select Password box
	// Enter an invalid password
	// Click 'Go' button
	// Confirm presence of “Authentication Error” dialog
	// Click OK
	// Select Password box
	// Clear box
	// Click 'Go' button
	// Confirm presence of 'Invalid parameters' error dialog
	// Click OK
	// Select Password box
	//}ODOT
	
	// Enter a valid password, consisting of mixed-case alpha, numeric and special chars.  This will exercise the alpha, shift, and #+= screens and buttons. and Click ‘Go’ button
	defaultLogin(app);
	
	// TODO: Confirm temporary presence of “One Moment Please / Logging In” display.
	
	
	// Confirm landing page is the ‘People’ user list
	var title =  app.mainWindow().navigationBar().name()	
	assertEquals("People", title, "Should have loaded 'People' tab");
	logDebug("the count was " +  app.mainWindow().tableViews()[0].cells().length);
	assertTrue(count>0, "contacts should have loaded");
	
});

