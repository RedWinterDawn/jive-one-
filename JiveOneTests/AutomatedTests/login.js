var testName = "Login Test";
var target = UIATarget.localTarget();
var app = target.frontMostApp();
var window = app.mainWindow();

window.logElementTree();

window.textFields()["emailTextField"].setValue("jivetesting12@gmail.com");
window.secureTextFields()["passwordTextField"].setValue("testing12");
window.logElementTree();
app.keyboard().elements()["Go"].tap();

UIATarget.localTarget().pushTimeout(200);
window.navigationBar().name()["People"];
UIATarget.localTarget().popTimeout();

if(window.navigationBar().name() == "People"){
	target.delay(5);
	window.logElementTree();
	UIALogger.logPass( testName); 
}
else{
	UIALogger.logFail( testName ); 
}
