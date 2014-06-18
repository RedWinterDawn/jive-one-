//Testing the Voicemail tab and all the element in it
// Created By Peter Leonard
#import "../Common.js"
test("Voicemail", function(target, app){
	 //logoutIfNeeded(app);
	 //loginIfNeeded(app);
	 //Navagate to the voicemail tab
	 //target.frontMostApp().tabBar().buttons()["Voicemail"].tap();
	 //target.logElementTree();
	
	 target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[0].tap();
	 target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[0].logElementTree();
	 logDebug(target.frontMostApp().mainWindow().tableViews()["Empty list"].length());
	 target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["WIRELESS CALLER, 14:55 PM, 6/17/2014 02:55 PM, 1:54, 8177892390"].value();
	 target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[1];
	 target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[1].logElementTree;
	 
	 assertTrue(target.frontMostApp().tabBar().name(), "Voicemail");
	 
	 
	 //Check the new messages are bold 
	 
	 // test the speaker button3
	 
	 // toggle pause and play button make sure it is the correct one wile it is playing
	 
	 // check to see that the appearence of message updated to listened
	 
	 //Logout of app and log in and see if the messages are updated
	 
	 //Delete a message 
	 
	  
	
	
	 
	 
});