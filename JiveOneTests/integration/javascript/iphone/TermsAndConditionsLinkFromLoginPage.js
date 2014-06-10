#import "../Common.js"
test("Terms and Conditions link from login page", function(target, app){
	logoutIfNeeded(app);

target.frontMostApp().mainWindow().buttons()["Terms and Conditions."].tap();
delay(10);
app.mainWindow().logElementTreeJSON();
// target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].buttons()[""].tap();
// target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].links()["ENTERPRISE"].tap();
// target.frontMostApp().navigationBar().leftButton().tap();

});

