Writing Tests
==
Add tuneup.js
-
add to the beginning of your .js test file 
<br> 
<code>#import "../../../../../Pods/tuneup_js/tuneup.js"</code>

Declare a test
-
<pre>
test("Login screen", function(target, app) {
  // do cool stuff in here
});
</pre>

Excersice and Validate
-
<pre>
test("Login screen", function(target, app) {
  var window = app.mainWindow();

  //tap the left button in the navigation bar
  window.navigationBars()[0].leftButton().tap();

  // now assert that the app has navigated into a sub-view controller
  assertEquals("Settings", window.navigationBars()[0].value());
});
</pre>

Where to save
-
Place your test files in iOS-Jive/integration/javascript/iphone

Executing tests
==
open terminal 
<br>
<code>cd</code>
 to "iOS-JiveOne" 
<br>
<code> bwoken test —integration-path=JiveOneTests/integration —-skip-build </code>

No bwoken?
-
To install bwoken, 
<code>cd</code>
 to "iOS-JiveOne" 
<pre>
gem install bundler

bundle install
</pre>

More about tuneup.js
=
For more documentation about what utility functions and advantages tuneup.js gives you, refer to their documentation
http://www.tuneupjs.org/assertions.html <br>
http://www.tuneupjs.org/extensions.html