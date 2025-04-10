#import "../Common.js"

test("Send chat in new conversation and verify it was received", function(target, app){

	//setup{
	logoutIfNeeded(app);
	login(app, "jivetesting11@gmail.com", "testing12");
	
	//delete the conversation between testing11 and testing10
	app.mainWindow().tabBar().buttons()[2].tap();
	delay(1);
	var cell = app.mainWindow().tableViews()[0].cells().firstWithPredicate("name contains[c] 'Jive Testing 10'");
	if(cell.isNotNil()){
		logDebug("conversation with Jive Testing 10 exists. Will delete...");
		cell.dragInsideWithOptions({startOffset:{x:0.75, y:0.5}, endOffset:{x:0.15, y:0.5}, duration:0.5});
		cell.buttons()["Delete"].tap();
		delay(4.5);
}//}
	
	//create new conversation with Jive Testing 10
	target.frontMostApp().navigationBar().rightButton().tap();
	target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Jive Testing 10"].tap();
	
	//send a message
	delay(1);
	w = target.frontMostApp().mainWindow();
	delay(1);
	var beforeCount = w.tableViews()[1].cells().length;
	logDebug("before " + beforeCount.toString());

	var uniqueMessage = "my message " + new Date().toString();
	//enter message in message box
	w.images()[1].textViews()[0].tap();
	app.keyboard().typeString("first message");
	w.images()[1].buttons()["Send"].tap();
	// w.tableViews()[0].cells()[1].waitUntilVisible(10);
	delay(4);
	app.keyboard().typeString(uniqueMessage);
	w.images()[1].buttons()["Send"].tap();	
	delay(1);
	
//get count of cells in table view now that we've posted both messages.
	var afterCount = w.tableViews()[1].cells().length;
	logDebug("after: " + afterCount.toString());

	//verify the message shows in the feed
	assertTrue((beforeCount+2)==afterCount, "There should have been "+(beforeCount+2)+" message(s) but there were "+ afterCount);

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