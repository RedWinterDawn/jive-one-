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



Install Test flight
=
To install test flight app on your device you will need your Device added to the testflight group and to the develpoer povisioning profile
Open XCode
Pull latest version of the app from github
```
git clone https://github.com/jive/iOS-JiveOne.git
```

Then plug in the device directly into your computer.
Build the app using your device as the build target.
Then go to testflightapp.com on your device through safari.
Login and launch the app.
Install provisioning profile.

Testing login
username: jivetesting12@gmail.com
password: testing12

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



How to send a push notification through Parse web service
==========
```
curl -X POST  -H "X-Parse-Application-Id: pF8x8MNin5QJY3EVyXvQF21PBasJxAmoxA5eo16B"  
-H "X-Parse-REST-API-Key: KKGQt7I9D5mR1HlGn4fxwx8FbxH9LWfJ5iKGcqg6" 
-H "Content-Type: application/json"  
-d '{ 
	"where": 
		{"deviceToken": "9f4477a2408056e340cfdc0eaf9da40bd24639595e841f43fda28676502a51eb"}, 
	"data": 
		{ "message" : "silent remote", "content-available" : "1", "pushCode" : "1" }
	}' 
https://api.parse.com/1/push
```

How to SSH to API Server and Tail the Output
==========
Make sure you have the appropriate .pem files in your .ssh folder as well as a 'config' file. The config file contents shuld be:
```
Host my.jive.com
	IdentityFile ~/PATH/TO/FILE.pem
	HostName 10.103.1.74
	User root

Host test.my.jive.com
	IdentityFile ~/PATH/TO/FILE.pem
	HostName 10.103.0.137
	User root
```
In terminal, type the following command:
```
ssh my.jive.com
```
Accept the certificate and once you're in, to tail, type: 
```
tail -f/var/run/forever/*
```
Another useful command is to re-start the service. Type:
```
service jive_client restart
```

Upload a test voicemail
====
cd to a directory where msg0000.wav and msg0000.txt exists (such as /Assets).
<br>
then
<br>
curl -v -F file=@msg0000.WAV -F metadata=@msg0000.txt http://10.20.26.141:8880/voicemails/mailbox/0146de22-4cf6-65b5-3be8-006300620001/folders/INBOX

Some useful links:
==========

Understand blocks
http://code.tutsplus.com/tutorials/understanding-objective-c-blocks--mobile-14319
