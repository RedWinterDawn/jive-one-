#import "../Common.js"

test("Search Contacts", function(target, app){

	logoutIfNeeded(app);
	login(app, "jivetesting10@gmail.com", "testing12");

	// Confirm landing on People page!
	assertEquals(target.frontMostApp().mainWindow().navigationBar().name(), "People", "Should have loaded people view");
	// Select search box!
	target.frontMostApp().mainWindow().searchBars()[0].tap();
	// Enter ‘Rich’!	
	target.frontMostApp().keyboard().typeString("Testing");
	delay(1);
	// Confirm Search Results show 4 entries Lisa Richards 
	assertEquals(3, target.frontMostApp().mainWindow().tableViews()["Search results"].cells().length, "'Testing' should have 3 results");
	// Press ‘X’ in search window to clear search!
	target.tap({x:307.00, y:33.50});
	// Now type ‘x’!
	target.frontMostApp().keyboard().typeString("Testing 10");
	delay(1);
	// Confirm Search Results show 3 entries: 
	assertEquals(1, target.frontMostApp().mainWindow().tableViews()["Search results"].cells().length, "'Testing 10' should have 3 results");
	// Now type ‘z’!
	target.frontMostApp().keyboard().typeString("z");
	delay(1);
	// Confirm Search Results showing ‘No Results’ screen!
	assertEquals(0, target.frontMostApp().mainWindow().tableViews()["Search results"].cells().length, "'z' should have 0 results");
	// Press ‘X’ in search window to clear search!
	target.tap({x:307.00, y:33.50});
	// scroll down to resign keyboard

	// Confirm keyboard disappears!

})
