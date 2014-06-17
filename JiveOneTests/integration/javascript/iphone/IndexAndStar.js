#import "../Common.js"

test("Index and star", function(target, app){
	
// Log into Jive Mobile as jivetesting10@gmail.com
//logoutIfNeeded(app);
//login(app, "jivetesting10@gmail.com", "testing12");
// Confirm landing on People page!
var kFavoriteCell = "Jive Testing 17";
assertEquals(target.frontMostApp().mainWindow().navigationBar().name(), "People", "Should have loaded people view");
// Select ‘J’ index!
target.frontMostApp().mainWindow().tableViews()["Empty list"].elements()["table index"].tapWithOptions({tapOffset:{x:0.60, y:0.35}});
delay(2);
// Confirm J names showing!
assertTrue(arrayContainsCellWithName(kFavoriteCell, app.mainWindow().tableViews()["Empty list"].visibleCells()), kFavoriteCell +" cell not visible");
// Select ‘Jive Testing 17’!
logDebug("select "+kFavoriteCell)
// target.frontMostApp().mainWindow().tableViews()["Empty list"].cells().firstWithNameRegex(kFavoriteCell).tap();

// logDebug("tap that")
// delay(2);
// // Assert email, company information correct!
// assertEquals("Email, jivetesting17@gmail.com", app.mainWindow().tableViews()["Empty list"].cells()[1].name(), "Email information incorrect");//1
// assertEquals("Company, Integration Testing", app.mainWindow().tableViews()["Empty list"].cells()[2].name(), "Company information incorrect");//2
// // Toggle star on/off/on!
// target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[kFavoriteCell].buttons()["★"].tap();//0
// // Tap ‘< People’ to go back to R list (and confirm star is shiny)!
// target.frontMostApp().navigationBar().leftButton().tap();
// // Select star index!
// target.frontMostApp().mainWindow().tableViews()["Empty list"].elements()["table index"].tapWithOptions({tapOffset:{x:0.67, y:0.01}});//star
// Confirm both starred entries are present and listed!

// Select ‘More’ button!

// Sign Out!

// Sign back into Jive Mobile with the same valid credentials used previously!

// Confirm previously starred entries are still selected!

// Select ‘More’ button!

// Sign Out! 


});



