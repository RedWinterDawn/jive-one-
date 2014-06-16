#import "../Common.js"

test("Index and star", function(target, app){
	
// Log into Jive Mobile with valid credentials!
loginIfNeeded(app);
// Confirm landing on People page!
assertEquals(target.frontMostApp().mainWindow().navigationBar().name(), "People", "Should have loaded people view");
// Select ‘J’ index!
target.frontMostApp().mainWindow().tableViews()["Empty list"].elements()["table index"].tapWithOptions({tapOffset:{x:0.60, y:0.46}});
// target.frontMostApp().mainWindow().tableViews()["Empty list"].elements()["table index"].tapWithOptions({tapOffset:{x:0.50, y:0.42}});
// Confirm J names showing!
target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Jive Testing 17"].tap();//TODO:
// Select ‘Richard Tenney’!

// Assert email, company information correct!

// Toggle star on/off/on!

// Tap ‘< People’ to go back to R list (and confirm star is shiny)!

// Select ‘Q’ index!

// Assert 3 QA entries present: 

// QA Test  QA Test2  QA3 Test!

// Select QA Test2!

// Activate star!

// Tap ‘< People’ to go back to Q list (and confirm star is shiny)!

// Select star index!

// Confirm both starred entries are present and listed!

// Select ‘More’ button!

// Sign Out!

// Sign back into Jive Mobile with the same valid credentials used previously!

// Confirm previously starred entries are still selected!

// Select ‘More’ button!

// Sign Out! 


});





//detail
target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Jive Testing 17"].tap();//0
target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Email, jivetesting17@gmail.com"].tap();//1
target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Company, Integration Testing"].tap();//2
target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Jive Testing 17"].buttons()["★"].tap();//0
target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Jive Testing 17"].buttons()["★"].tap();
target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Jive Testing 17"].buttons()["★"].tap();
target.frontMostApp().navigationBar().leftButton().tap();
target.frontMostApp().mainWindow().tableViews()["Empty list"].elements()["table index"].tapWithOptions({tapOffset:{x:0.67, y:0.01}});//star