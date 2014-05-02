var testName = "Verify each tab exists and loads";
var target = UIATarget.localTarget();
var app = target.frontMostApp();
var window = app.mainWindow();

target.delay(5);
window.logElementTree();