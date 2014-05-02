#import "Common.js"

test("Receive a chat", function(target, app){

	var mainWindow = app.mainWindow();

	//navigate to chat window
	var conversations = mainWindow.tabBar().buttons()[2];
	conversations.tap();
	target.delay(1);
	assertEquals("Conversations", app.mainWindow().navigationBar().name(), "Title should be 'Conversations'");

	//select a person to chat
	//if none exist, create one

	//send a message

	//verify that the recipient received the message
	

	more.tap();
	target.delay(1);
	assertEquals("Account", app.mainWindow().navigationBar().name(), "Title should be 'Account'");
	
});