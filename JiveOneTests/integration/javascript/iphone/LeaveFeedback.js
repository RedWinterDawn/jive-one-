#import "../Common.js"

test("Leave Feedback", function(target, app){
	loginIfNeeded(app);

target.frontMostApp().tabBar().buttons()["Account"].tap();
target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Leave Feedback"].tap();
delay(2);
target.frontMostApp().mainWindow().logElementTree();
target.frontMostApp().mainWindow().scrollViews()[0].textViews()["Message body"].tapWithOptions({tapOffset:{x:0.59, y:0.20}});
delay(1);
// target.frontMostApp().mainWindow().scrollViews()[0].textViews()[1].typeString(uniqueMessage);
if(target.isDeviceiPhone5()){
	target.frontMostApp().navigationBar().tapWithOptions({tapOffset:{x:0.98, y:0.16}});
}else
{
	//get other coordinates?
	target.frontMostApp().navigationBar().tapWithOptions({tapOffset:{x:0.98, y:0.16}});
}


});