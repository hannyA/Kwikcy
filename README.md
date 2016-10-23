# Kwikcy
Kwikcy is an iOS app that works with a Java backend on AWS 

# About
Kwikcy is an iOS app that let users share ephermal photos and videos. The app includes features that made users aware of each others morals( i.e. honesty, revenge, mercy). Users cannot be prevented from taking screenshots, but the users whos shared photos were taken a screenshot of, have the ability to take revenge on said person. The implementation is incomplete. Though the options were to either: 1)Select a random photo from the guilty party's past sent photos and share it amongst friends of both parties (a bit dangerous). 2) Allow the person to take screenshots of the guilty party at a later date without any notification. 3) Send a message to the friends of the guilty party of his betrayal.

One of the more important functionality would be the coredata database on the client side (iOS) that would store all off network interactions with photos. So for example: An issue with snapchat is that people turn off their internet access, view photos and take screenshots. Since they're off the network, Snapchat does not receive a notification of the screenshot. 

The function I built would capture this data and then send it to the servers when the phone's network access is restored 10 seconds later.

The app includes the ability to search for users by name or by people in their address book. Receive notifications of new friend requests and screentshot notificiation. 

# History
Kwikcy was first built using iOS 5 and continued being over the years until 2014, when iOS 8 came out (I think it's time to call it quits).

#Libraries/Frameworks
AWS Mobile Framework including AWS TokenVendingMachine that I altered to use DynamoDB instead of SimpleDB.
DLCImagePicker
GPUImage
MBProgressHUD
More that I can't find because it's been so long
