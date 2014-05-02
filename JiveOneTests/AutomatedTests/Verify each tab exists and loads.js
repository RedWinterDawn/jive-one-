#import "Common.js"

test("Verify each tab exists and loads", function(target, app){

	var mainWindow = app.mainWindow();

	app.logElementTree();

	var people = mainWindow.tabBar().buttons()[0];
	var voicemail = mainWindow.tabBar().buttons()[1];
	var conversations = mainWindow.tabBar().buttons()[2];
	var more = mainWindow.tabBar().buttons()[3];

//assert all the buttons exists
	assertEquals("People", people.name(), "The name should be 'People'");
	assertEquals("Voicemail", voicemail.name(), "The name should be 'People'");
	assertEquals("Conversations", conversations.name(), "The name should be 'People'");
	assertEquals("More", more.name(), "The name should be 'People'");

//make sure all the buttons are clickable and that the view loads with the expected title



	
});