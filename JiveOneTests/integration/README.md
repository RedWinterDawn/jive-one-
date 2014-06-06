#Integration Testing using tuneup_js

##Writing Tests

####Add tuneup.js

add to the beginning of your .js test file 
<br> 
<code>#import "../../../../../Pods/tuneup_js/tuneup.js"</code>

####Declare a test

<pre>
test("Login screen", function(target, app) {
  // do cool stuff in here
});
</pre>

####Excersice and Validate

<pre>
test("Login screen", function(target, app) {
  var window = app.mainWindow();

  //tap the left button in the navigation bar
  window.navigationBars()[0].leftButton().tap();

  // now assert that the app has navigated into a sub-view controller
  assertEquals("Settings", window.navigationBars()[0].value());
});
</pre>

####Where to save

Place your test files in iOS-Jive/integration/javascript/iphone

##Executing tests

open terminal 
<br>
<code>cd</code>
 to "iOS-JiveOne" 
<br>
<code> bwoken test —integration-path=JiveOneTests/integration —-skip-build </code>
<br>
or to run a single test i.e. "login.js"
<br>
<code> bwoken test —integration-path=JiveOneTests/integration —-skip-build  --focus login</code>
<br>
View all optional parameters by typing 
<code>bwoken test -h</code>
<br>

####No bwoken?

To install bwoken, 
<code>cd</code>
 to "iOS-JiveOne" 
<pre>
gem install bundler

bundle install
</pre>

####Broken bwoken?

One other thing to note is that bwoken does not take kindly to killing a test part way through. Let the test complete and do not try to end the process or you it will hang and you won't be able to run more tests. The two fixes that i've found for this are <br><br>1) Restart (most reliable as will definitely kill any hanging processes) <br> 2) this script <pre>for proc in $(ps aux | grep -E "(bwoken|ScriptAgent)" | grep `whoami` | awk '{print $2}'); do for sig in 3 6 9; do kill -$sig $proc; done; done</pre>

##More about tuneup.js

For more documentation about what utility functions and advantages tuneup.js gives you, refer to their documentation
http://www.tuneupjs.org/assertions.html <br>
http://www.tuneupjs.org/extensions.html