#import "../Common.js"

test("Eula & Terms of Service", function(target, app){
	loginIfNeeded(app);

	target.frontMostApp().tabBar().buttons()["Account"].tap();
target.frontMostApp().logElementTree();
delay(5);
UIATarget.localTarget().pushTimeout(200);
target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["End User License Agreement"].tap();
UIATarget.localTarget().popTimeout();
delay(6);
target.frontMostApp().mainWindow().logElementTree();
assertTrue(target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].links()[0].name().contains("877-548-3007"), "Jive phone number link not found");
assertTrue(target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].links()[1].name().contains("SUPPORT"), "Jive support link not found");
assertTrue(target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].staticTexts()[1].name().contains("Mobile End User License Agreement"), "Agreement not found");

//exit
target.frontMostApp().navigationBar().tapWithOptions({tapOffset:{x:0.01, y:0.39}});
	
});