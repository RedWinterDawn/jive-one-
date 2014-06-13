#import "../Common.js"

test("Search Contacts", function(target, app){

	loginIfNeeded(app);

	// Confirm landing on People page!
	assertEquals(target.frontMostApp().mainWindow().navigationItem().name, "People", "Should have loaded people view");
	// Select search box!
	target.frontMostApp().mainWindow().searchBars()[0].tap();
	// Enter ‘Rich’!	
	target.frontMostApp().keyboard().typeString("Testing");
	delay(1);
	// Confirm Search Results show 4 entries:  Lisa Richards 
	assertEquals(target.frontMostApp().mainWindow().tableViews()[0].cells().count, 3, "Testing should have 3 results");
	// Press ‘X’ in search window to clear search!
	target.tap({x:307.00, y:33.50});
	// Now type ‘x’!
	target.frontMostApp().keyboard().typeString("Testing 10");
	delay(1);
	// Confirm Search Results show 3 entries: 
	assertEquals(target.frontMostApp().mainWindow().tableViews()[0].cells().count, 1, "Testing should have 3 results");
	// Now type ‘z’!
	target.frontMostApp().keyboard().typeString("z");
	delay(1);
	// Confirm Search Results showing ‘No Results’ screen!
	assertEquals(target.frontMostApp().mainWindow().tableViews()[0].cells().count, 0, "Testing should have 3 results");
	// Press ‘X’ in search window to clear search!
	target.tap({x:307.00, y:33.50});
	// Tap ‘123’ button!

	// Select ‘(‘!

	// Confirm ‘Steven Greiwe (TGP 550)’ is displayed!

	// Select ‘Search’ button at bottom of screen!

	// Confirm keyboard disappears!

})
