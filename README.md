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