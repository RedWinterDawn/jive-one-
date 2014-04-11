###iOS-JiveOne
===========

Install ruby 2.0, then:
```
gem install cocoapods
```

Navigate to the source file and run:
```
pod install
```

ALWAYS use Jive.xcworkspace, not Jive.xcodeproj


One feature that was implemented and then hidden was to display local contacts (on the phone in the address book app). This was show via segment control on the "directory" tab. The segmented control, however, was hidden and a search bar is now in its place. Segmented control can be seen by going into the storyboard and un-hiding it. 


TESTING AND USING OCMOCK
==============
Check out: http://en.wikipedia.org/wiki/Mock_object for a detailed explination of Mock objects and why we use them.

Use the following guidelines when deciding to use OCMock or not:

If an actual object has any of the following characteristics, it may be useful to use a mock object in its place.

If the real object:
* supplies non-deterministic results (e.g., the current time or the current temperature);
* has states that are difficult to create or reproduce (e.g., a network error);
* is slow (e.g., a complete database, which would have to be initialized before the test);
* does not yet exist or may change behavior;
* would have to include information and methods exclusively for testing purposes (and not for its actual task).

For example, an alarm clock program which causes a bell to ring at a certain time might get the current time from the outside world. To test this, the test must wait until the alarm time to know whether it has rung the bell correctly. If a mock object is used in place of the real object, it can be programmed to provide the bell-ringing time (whether it is actually that time or not) so that the alarm clock program can be tested in isolation.









==========
Some useful links:

Understand blocks
http://code.tutsplus.com/tutorials/understanding-objective-c-blocks--mobile-14319

How to send a push notification through Parse web service
curl -X POST  -H "X-Parse-Application-Id: pF8x8MNin5QJY3EVyXvQF21PBasJxAmoxA5eo16B"  
-H "X-Parse-REST-API-Key: KKGQt7I9D5mR1HlGn4fxwx8FbxH9LWfJ5iKGcqg6" 
-H "Content-Type: application/json"  
-d '{ 
	"where": 
		{"deviceToken": "9f4477a2408056e340cfdc0eaf9da40bd24639595e841f43fda28676502a51eb"}, 
	"data": 
		{"alert": "If you got this, tell Daniel"} 
	}' 
https://api.parse.com/1/push