var target = UIATarget.localTarget();
var app = target.frontMostApp();
var window = app.mainWindow();

window.logElementTree();

window.textFields()["emailTextField"].setValue("jivetesting12@gmail.com");
window.secureTextFields()["passwordTextField"].setValue("testing12");
window.logElementTree();
app.keyboard().elements()["Go"].tap();

UIATarget.localTarget().pushTimeout(20);
window.navigationBar().name()["CompanyDirectory"];
UIATarget.localTarget().popTimeout();