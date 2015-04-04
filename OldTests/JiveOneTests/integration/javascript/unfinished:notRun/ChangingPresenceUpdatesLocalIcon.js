#import "../Common.js"

test("Changing Presence updates local icon", function(target, app){
	
// Login with valid credentials
loginIfNeeded(app)
// Navigate to more tab
app.mainWindow().tabBar().buttons()[3].tap();
// Capture state of current presence icon
var presenceCell = target.frontMostApp().mainWindow().tableViews()["Empty list"].visibleCells()[2].name();
var changeTo = ""
if(presenceCell=="Available"){
	changeTo = "Busy"
}else{
	changeTo = "Available"
}
// Change presence to something else
target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[2].tap();
delay(2);
logDebug("changeTo:"+changeTo)
target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[changeTo].tap();
delay(2);
// Verify that the icon has changed
assertEquals(changeTo, target.frontMostApp().mainWindow().tableViews()["Empty list"].visibleCells()[2].name(), "Presence should have changed to "+ changeTo);
// Change presence back to first state
target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[2].tap();
target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[presenceCell].tap();
delay(2);
// Verify that the icon has changed, back to first state
assertEquals(presenceCell, target.frontMostApp().mainWindow().tableViews()["Empty list"].visibleCells()[2].name(), "Presence should have changed BACK to "+presenceCell);

});
