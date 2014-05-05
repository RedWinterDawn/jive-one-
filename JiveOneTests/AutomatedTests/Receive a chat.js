#import "Common.js"

test("Receive a chat", function(target, app){


	var w = app.mainWindow();

	//navigate to chat window
	navigateToConversationWindow(app);

	//send a message
	w = app.mainWindow();
	target.delay(1);
	var beforeCount = w.tableViews()[0].cells().length;

	var uniqueMessage = "my message " + new Date().toString();
	w.images()[0].textViews()[0].tap();
	app.keyboard().typeString(uniqueMessage);
	w.images()[0].buttons()["Send"].tap();

	var afterCount = w.tableViews()[0].cells().length;

	assertTrue((beforeCount+1)==afterCount, "There should have been "+(beforeCount+1)+" but there were "+ afterCount);

	//give it 3 seconds to actually post the message
	target.delay(3)

	//verify that the recipient received the message by logging out of jivetesting11 and into jivetesting10, then checking messages
	//go to logout page
	w.navigationBar().leftButton().tap();
	app.mainWindow().tabBar().buttons()[3].tap();
	target.logElementTree();
	
	var recipient = app.mainWindow().tableViews()[0].cells()[0].name();
	UIALogger.logDebug("logged in as:" + recipient);
	if(recipient.contains("jivetesting10@gmail.com"))
	{
		recipient = "jivetesting11@gmail.com";
	}else{
		recipient = "jivetesting10@gmail.com";
	}

	app.mainWindow().navigationBar().buttons()["Logout"].tap();
	UIALogger.logDebug("will log in as: "+ recipient);

	app.mainWindow().textFields()["emailTextField"].setValue(recipient);
	app.mainWindow().secureTextFields()["passwordTextField"].setValue("testing12");
	app.keyboard().elements()["Go"].tap();

	//wait for login
	target.pushTimeout(200);
	app.mainWindow().navigationBar().name()["People"];
	target.popTimeout();

	//navigate to conversations tab
	navigateToConversationWindow(app);

	//assert that message we sent is in this conversation
	target.delay(2);

	assertTrue(app.mainWindow().tableViews()[0].cells()[uniqueMessage], "Table View did not contain most recently sent message");
	
	
});


function navigateToConversationWindow(app){
	//navigate to chat window
	app.mainWindow().tabBar().buttons()[2].tap();
	UIATarget.localTarget().delay(1);
	assertEquals("Conversations", app.mainWindow().navigationBar().name(), "Title should be 'Conversations'");
	//TODO: ? pull down refresh?

	//select a person to chat
	app.mainWindow().tableViews()[0].cells()[0].tap();
}