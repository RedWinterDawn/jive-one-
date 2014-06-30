#import "../Common.js"

test("Verify each tab exists and loads", function(target, app){
	loginIfNeeded(app);

	var mainWindow = app.mainWindow();

	// var people = mainWindow.tabBar().buttons()[0];
	var voicemail = mainWindow.tabBar().buttons()[0];
	// var conversations = mainWindow.tabBar().buttons()[2];
	var more = mainWindow.tabBar().buttons()[1];

//assert all the buttons exist
	// assertEquals("People", people.name(), "The name should be 'People'");
	assertEquals("Voicemail", voicemail.name(), "The name should be 'Voicemail'");
	// assertEquals("Conversations", conversations.name(), "The name should be 'People'");
	assertEquals("Account", more.name(), "The name should be 'Account'");

//make sure all the buttons are clickable and that the view loads with the expected title
	voicemail.tap();
	target.delay(1)
	 assertEquals("Voicemail", app.mainWindow().navigationBar().name(), "Title should be 'Voicemail'");

	// conversations.tap();
	// target.delay(1);
	// assertEquals("Conversations", app.mainWindow().navigationBar().name(), "Title should be 'Conversations'");

	more.tap();
	target.delay(1);
	assertEquals("Account", app.mainWindow().navigationBar().name(), "Title should be 'Account'");
	
});