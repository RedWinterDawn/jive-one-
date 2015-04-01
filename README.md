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

TESTING
===============
There are many different types of tests. Here at jive we would like to have tests so that we can verify our code is robust and verify services are up.
Here are the different types of tests we can have:

Unit Tests- These test a single pice of code. These are required for a story to be passed off and accepted.


Integration tests - Tests anything that makes a call to an api or external service. These should be created when a portion of the app is complete in a general were we want it to be. 

UITests - the testing of the visual elements on a view similar to units tests but for the visual elements and their connections to the app. They should be created once a view has been added to the app. 

Automation tests - will be excited by the continues integration server. A story should be added and created once a feature is “Done” to create a Automated visual continues integration test. That way when new code is being added to the project we can know early on that it has crashed. 


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


```
OR
<code>
https://www.getpostman.com/collections/7dfcf8a716b5f833c39e
</code>

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
