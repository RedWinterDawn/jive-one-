#import "Common.js"

test("Receive a chat", function(target, app){

	var w = app.mainWindow();

	//navigate to chat window
	var conversations = mainWindow.tabBar().buttons()[2];
	conversations.tap();
	target.delay(1);
	assertEquals("Conversations", app.mainWindow().navigationBar().name(), "Title should be 'Conversations'");

	//select a person to chat
	app.mainWindow().logElementTree();
	w = app.mainWindow();
	var cell = w.tableViews()[0].cells["The Bar"];
	cell.tap();
	target.delay(1);

	//send a message
	app.Keyboard().keys("Your message");
	app.mainWindow().logElementTree();
	app.keyboard().elements()["Send"].tap();

	//verify that the recipient received the message
	

	more.tap();
	target.delay(1);
	assertEquals("Account", app.mainWindow().navigationBar().name(), "Title should be 'Account'");
	
});