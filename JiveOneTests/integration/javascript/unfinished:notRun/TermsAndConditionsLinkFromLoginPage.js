#import "../Common.js"
test("Terms and Conditions link from login page", function(target, app){
	logoutIfNeeded(app);

// Confirm 'Terms and Conditions' text at bottom is an active link by clicking on it.
target.frontMostApp().mainWindow().buttons()["Terms and Conditions."].tap();
target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].buttons()[0].waitUntilVisible(30);

// TODO: Confirm landing page displays the Jive Terms and Conditions text.
app.mainWindow().logElementTreeJSON();
// target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].buttons()[""].tap();
// target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].links()["ENTERPRISE"].tap();

// Click 'X' at top to return to Login page.
target.frontMostApp().navigationBar().leftButton().tap();

// TODO: Confirm return to login page

});

