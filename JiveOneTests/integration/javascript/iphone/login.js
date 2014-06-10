#import "../Common.js"

test("Login Test", function(target, app){
	
	logoutIfNeeded(app);
	
	defaultLogin(app);
	
	var currentWindow = app.mainWindow();

	//capture navigation bar name
	var title = currentWindow.navigationBar().name()

	//get count of contacts
	var contactsList = currentWindow.tableViews()[0];
	var count = contactsList.cells().length;

	assertEquals("People", title, "Should have loaded 'People' tab");
	logDebug("the count was " + count);
	assertTrue(count>0, "contacts should have loaded");
});

