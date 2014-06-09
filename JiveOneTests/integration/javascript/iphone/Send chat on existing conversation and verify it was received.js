#import "../../../../../Pods/tuneup_js/tuneup.js"

test("Send chat on exisiting conversation and verify it was received", function(target, app){

	logoutIfNeeded(app);
	login(app, "jivetesting11@gmail.com", "testing12");

	var w = app.mainWindow();

	//navigate to chat window
	navigateToConversationWindow(app, "Jive Testing 10");

	//send a message
	w = app.mainWindow();
	target.delay(1);
	var beforeCount = w.tableViews()[0].cells().length;

	var uniqueMessage = "my message " + new Date().toString();
	//enter message in message box
	w.images()[1].textViews()[0].tap();
	app.keyboard().typeString(uniqueMessage);
	w.images()[1].buttons()["Send"].tap();

	var afterCount = w.tableViews()[0].cells().length;

	//verify the message shows in the feed
	assertTrue((beforeCount+1)==afterCount, "There should have been "+(beforeCount+1)+" but there were "+ afterCount);

	//give it 3 seconds to actually post the message
	target.delay(3)
	
	//verify that the recipient received the message by logging out of jivetesting11 and in as jivetestin12
	//back button
	w.navigationBar().leftButton().tap();
	logout(app);

	//login as recipient of message
	login(app, "jivetesting10@gmail.com", "testing12");

	//navigate to conversations tab
	navigateToConversationWindow(app, "Jive Testing 11");

	//assert that message we sent is in this conversation
	target.delay(2);

	assertTrue(app.mainWindow().tableViews()[0].cells()[uniqueMessage], "Table View did not contain most recently sent message");
	
	
});


function navigateToConversationWindow(app, correspondent){
	//navigate to chat window
	app.mainWindow().tabBar().buttons()[2].tap();
	UIATarget.localTarget().delay(1);
	assertEquals("Conversations", app.mainWindow().navigationBar().name(), "Title should be 'Conversations'");
	//TODO: ? pull down refresh?

	//find conversation with either jivetesting12 or jivetesting11
	target.logElementTree();
	app.mainWindow().tableViews()[0].cells().firstWithPredicate("name contains[c] '" + correspondent +"'").tap();
}