#import "../../../../Pods/tuneup_js/tuneup.js"
function loginIfNeeded(app) {

        UIALogger.logDebug("test if we are logged out...");
        if (app.mainWindow().textFields()[0].name() == "emailTextField") {
           defaultLogin(app);
        }else{
          UIALogger.logDebug("Already logged in.");  
        }
}

function logoutIfNeeded(app) {
    UIALogger.logDebug("test if we are logged out...");
    if (app.mainWindow().textFields()[0].name() == "emailTextField") {
        //do nothing
        UIALogger.logDebug("Already logged out.");  
    }else{
      logout(app)
    }
}

function defaultLogin(app) {
    login(app, "jivetesting12@gmail.com", "testing12");
}

function login(app, user, password) {
    var currentWindow = app.mainWindow();
    logDebug("Logging in as " + user + " with password: " + password);
    
    //login
    currentWindow.textFields()["emailTextField"].setValue(user);
    currentWindow.textFields()["passwordTextField"].setValue(password);
    app.keyboard().typeString(password);
    app.keyboard().elements()["Go"].tap();
    
    //wait for login
    UIATarget.localTarget().pushTimeout(200);
    currentWindow.navigationBar().name()["Voicemail"];
    UIATarget.localTarget().popTimeout();
    
    UIATarget.localTarget().delay(2);
}

function logout(app) {
    app.mainWindow().tabBar().buttons()[2].tap();
    target.logElementTree();
        
    // scrollDown(200);
    // delay(2);
    app.mainWindow().tableViews()[0].cells()["Sign Out"].tap();

}

function logDebug(s){
    UIALogger.logDebug(s)
}

function scrollDown(pixels){

    var y1 = 400;
    var y2 = y1-pixels;

    UIATarget.localTarget().flickFromTo({x:160, y:y1}, {x:160, y:y2});
}
function scrollDownFromTo(start, end){

    var y1 = start;
    var y2 = end;

    UIATarget.localTarget().flickFromTo({x:160, y:y1}, {x:160, y:y2});
}

function delay(time){
    this.target.delay(time);
}

//searches an array and determines if the name of the cell (first param) is found. if true, will return index of cell in array. if not present, returns -1.
function arrayContainsCellWithName(name, array){
    var count = array.length;
    for(i=0;i<count;i++){
        var row = array[i].name();
        if(row.contains(name)){
            return i;
        }
    }
    return -1;
}

//pass in the entire array of elements from a tableView. second parameter is a string of the group name. Will return count of cells for that group
function countCellsInGroup(elementsArray, countTrigger){
    var cellsCount = -1;
    var countIt = false;
    
    for (var i = 0; i < elementsArray.length; i++) {
        if(countIt){
            //cells that are part of the star group
            cellsCount++;
        }
        if(elementsArray[i].toString().contains("UIATableGroup")){
            if(elementsArray[i].staticTexts()[0].name().contains(countTrigger)){
                countIt = true;
            }else{
                countIt = false;
            }
        }
        
    };
    logDebug("found "+ cellsCount + " cells for group with title "+ countTrigger)
    return cellsCount;
}

String.prototype.contains = function(it) { return this.indexOf(it) != -1; };