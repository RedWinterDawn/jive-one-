//Testing the Voicemail tab and all the element in it
// Created By Peter Leonard
#import "../Common.js"

test("Voicemail", function(target, app) {
  //loginIfNeeded();
  target.frontMostApp().tabBar().buttons()["Voicemail"].tap();
  assertWindow({
    tableViews: [
      {
        cells: [
          { name: "callerid" },
        ]
      }
    ]
  });
});