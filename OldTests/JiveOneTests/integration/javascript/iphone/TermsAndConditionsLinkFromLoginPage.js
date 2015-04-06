#import "../Common.js"
test("Terms and Conditions link from login page", function(target, app){
	logoutIfNeeded(app);
	//Dismiss the keybaord if preasent
	target.tap({x:287.50, y:112.00});
	target.frontMostApp().logElementTree();
	//Touch Terms and Conditions link at bottom of page
	target.frontMostApp().mainWindow().buttons()["Terms and Conditions."].tap();
	delay(2);
	 //Select the Menu
	target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].buttons()[""].tap();
	assertTrue(target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].links()["ENTERPRISE"],"ENTERPRISE tab not found");
	target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].links()["GOVERNMENT"].tap();
	delay(2);
	target.frontMostApp().logElementTree();
	//Test all the navagation buttons on the bottom of screen
	target.frontMostApp().toolbar().buttons()["Back"].tap();
	delay(2);
	target.frontMostApp().toolbar().buttons()["Forward"].tap();
	delay(2);
	target.frontMostApp().toolbar().buttons()["Back"].tap();
	delay(2);
	target.frontMostApp().toolbar().buttons()["Refresh"].tap();
	target.frontMostApp().toolbar().buttons()["Share"].tap();
	delay(2);
	target.frontMostApp().actionSheet().cancelButton().tap();
	delay(2);
	target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].tapWithOptions({tapOffset:{x:0.12, y:0.01}});
	target.frontMostApp().navigationBar().leftButton().tap();

	//We should now be in the login screen


});
