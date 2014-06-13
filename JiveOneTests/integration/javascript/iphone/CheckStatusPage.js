#import "../Common.js"

test("Check Status Page", function(target, app){
	loginIfNeeded(app);

//click status
	// target.frontMostApp().navigationBar().tapWithOptions({tapOffset:{x:0.06, y:0.07}});
	target.frontMostApp().navigationBar().buttons()["Status"].tap();
	delay(3);
	//confirm loading of status page
	//Assert that each of the expected tableview sections are present
	assertEquals(1, app.mainWindow().tableViews().length, "More than 1 table view?")
	assertWindow({
		navigationBar:{
			leftButton : { name: "People"},
			rightButton : { name: "Refresh"}
		}
		,
		tableViews: [
		{
			groups:
				[
					{ name: "Socket Status" },
					{ name: "Socket Events Subscription"},
					{ name: "Server is Reachable"},
					{ name: "Auth Token is Valid"},
					{ name: "Device Token"},
					{ name: "Last Socket Event"}
				]
			,	

			cells: 
				[
					{ name: null},
					{ name: null},
					{ name: null},
					{ name: null},
					{ name: null},
					{ name: null},
					{ name: null}
				]
		}
		
		]
	});
	// logDebug("assertWindow done");
	// logDebug(app.mainWindow().tableViews()[0].cells()[1].elements()[0].staticTexts()[0].value);

	// logDebug("5 labels");
	// assertMatch("Label*", app.mainWindow().tableViews()[0].cells()[1].elements()[0].staticTexts()[0], "Should be 5 labels");
	// logDebug("server name");
	// assertMatch("https://*my\.jive\.com", app.mainWindow().tableViews()[0].cells()[2].name, "Should be the server name");
// target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Open"].tap();
// target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Label, Subscribed to 0 events, Label, Label, Label"].tap();
// target.frontMostApp().navigationBar().tapWithOptions({tapOffset:{x:0.98, y:0.23}});

	// Click refresh icon (upper right) and ensure reload/refresh
target.frontMostApp().navigationBar().rightButton().tap();

//Click ‘<People’ back button!
//Conﬁrm return to People page!
target.frontMostApp().navigationBar().leftButton().tap();
assertEquals("People", target.frontMostApp().navigationBar().name(), "Should have loaded people page");



});