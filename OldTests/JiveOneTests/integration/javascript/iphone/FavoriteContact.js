#import "../Common.js"

test("Pressing the star on a contact, favorites, then unfavorites a contact", function(target, app){

	loginIfNeeded(app);

	//navigate to directory view
	app.mainWindow().tabBar().buttons()[1].tap();
	delay(1);
	assertEquals("People", app.mainWindow().navigationBar().name(), "Title should be people");

	//get count of contacts in favorites group
	var elements = app.mainWindow().tableViews()[0].elements();
	var beforeCount = countCellsInGroup(elements, "★")
	delay(1);
	
	//add 1
	logDebug("favoriting or unfavoriting contact now");	
	target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Cisco SupportLab, 1062"].buttons()["★"].scrollToVisible();
	delay(1);
	target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Cisco SupportLab, 1062"].buttons()["★"].tap();
	delay(1);

	//make sure that count has gone up
	var afterCount = countCellsInGroup(app.mainWindow().tableViews()[0].elements(), "★");

	assertNotEquals(beforeCount, afterCount, "Count should have increased");

	// target.logElementTree();

});


// var target = UIATarget.localTarget();

// target.frontMostApp().tabBar().buttons()["People"].tap();
// target.frontMostApp().mainWindow().tableViews()["Empty list"].tapWithOptions({tapOffset:{x:0.88, y:0.32}});
// target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[0].tap();
// target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[0].tap();
// target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[1].tap();
// target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Andrew Barkoff, 1019"].tap();
// target.frontMostApp().mainWindow().tableViews()["Empty list"].groups()["A"].tapWithOptions({tapOffset:{x:0.07, y:0.43}});
// target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Andrew Barkoff, 1019"].staticTexts()["Andrew Barkoff, 1019"].scrollToVisible();
// target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Angela Brunst, 1042"].staticTexts()["Angela Brunst, 1042"].scrollToVisible();
// target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[0].tap();
// target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[1].staticTexts()["Alan Palmer, 1229"].scrollToVisible();
// target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Andrew Barkoff, 1019"].touchAndHold(1.2);
// target.frontMostApp().mainWindow().tableViews()["Empty list"].groups()["★"].tapWithOptions({tapOffset:{x:0.07, y:0.59}});
// target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[1].buttons()["★"].tap();
