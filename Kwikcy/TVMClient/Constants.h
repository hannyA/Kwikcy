/*
 * Copyright 2010-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */




// Used as part of salt
#define KWIKCY_ENDPOINT    @"connect.kwikcy.com"
/**
 * This is the App Name you may have provided in the AWS Elastic Beanstalk
 * configuration.  It was the value provided for PARAM2.
 */
#define APP_NAME                     @"Kwikcy"

#define USE_SSL                      YES


#define CONNECTION_ERROR            @"Kwikcy connection error"

/**
 * The Amazon S3 Bucket in your account to use for this application.
 */


#define KWIKCY_VERSION                  @"1"
#define KWIKCY_PUBLIC_FILE              @"kwikcy-info.json"

#define KWIKCY_PUBLIC_URL_BASE          @"https://s3.amazonaws.com/kwikcy-public/"
#define PUBLIC_KWIKCY_BUCKET            @"kwikcy-public"



#define PRIVACY_POICY                   @"privacy-policy"
#define TERMS_OF_SERVICE                @"terms-of-service"
#define HELP_CENTER                     @"help-center"


#define KEY                             @"key"
#define ACCESS_KEY                      @"accessKey"
#define SECRET_KEY                      @"secretKey"
#define SECURITY_TOKEN                  @"securityToken"
#define EXPIRATION_DATE                 @"expirationDate"



            /****************** NOTIFICATIONS **************************/

#define ReceivedUserDetailsNotification @"receivedUserDetailsNotification"

#define KwikcyFileUpload                @"KwikcyFileUpload"

#define PERCENTAGE_COMPLETE              @"percentageComplete"

#define BUCKET_NAME                     @"kwikcy-users"
#define BUCKET_NAME_TMP                 @"kwikcy-users-tmp"
#define KWIKCY_PROFILE_BUCKET           @"kwikcy-users-profile"
#define KWIKCY_WORLD_BUCKET             @"kwicky-world-photos"


#define PROFILE_IMAGES                  @"profile_images"
#define SMALL_IMAGE                     @"small_image.jpg"
#define MEDIUM_IMAGE                    @"medium_image.jpg"
#define LARGE_IMAGE                     @"large_image.jpg"




#define BUCKET_URL                      @"https://kwikcy.s3.amazonaws.com"

#define USE_SERVER_SIDE_ENCRYPTION     YES







            /************ DYNAMODB TABLES AND KEYS ***********/



#define QPUSERS_SEARCH_TABLE            @"kcUserSearch"
#define PREFIX                          @"P"
//define USERNAME                       @"U"

//#define REALNAME                      @"R"
#define FollowingAllowed                @"AF"
#define ContactAllowed                  @"AC"


            /*********   Mobile number search **********/

#define MOBILE_SEARCH_TABLE             @"kcMobileSearch"
#define USER_MOBILE_NUMBER              @"uMob"

//Attrubutes
#define CONTACTS_NUMBER                 @"conMob"


        /****************   User profile *******************/


#define IN_THE_ADDRESS_BOOK             @"inBook"



//#define ANYONE                                      @"y"
//#define ANYONE_WITH_PERMISSION                      @"yp"
//#define PRIVATE                                     @"p"
//
//#define IM_IN_THE_ADDRESS_BOOK                      @"me-a" // yes
//#define IM_IN_THE_ADDRESS_BOOK_WITH_PERMISSION		@"me-ap" // yes




#define STATUS_PENDING                  @"pending"

#define STATUS_REQUESTER_PENDING        @"reqer_pend"
#define STATUS_REQUESTEE_PENDING        @"reqee_pend"

#define STATUS_FRIEND                       @"F"
#define FRIEND_ASYM_KNOWKINGLY              @"FK"
#define FRIEND_ASYM_UNKNOWINGLY             @"FU"
#define FRIEND_ASYM_UNKNOWINGLY_KNOWINGLY   @"FUK"

#define STATUS_DENIER                   @"denier"
#define STATUS_DENIED                   @"denied"

#define STATUS_BLOCKER                  @"blocker"
#define STATUS_BLOCKED                  @"blocked"





#define USER_ADD_STATUS_PUBLIC                          @"y"
#define USER_ADD_STATUS_PRIVATE                         @"yp"
#define USER_ADD_STATUS_PRIVATE_ALLOW_ADDRESS_BOOK      @"ap"


#define ANYONE_CAN_SEARCH_MY_MOBILE             @"y"
#define ADDRESS_BOOK_ONLY_CAN_SEARCH_MY_MOBILE  @"a"
#define NO_ONE_CAN_SEARCH_MY_MOBILE             @"n"







//#define QPUSERS_TABLE                   @"kcUser"
#define QPDEVICE_TABLE                  @"kcDevice"

#define OUTBOX_TABLE                    @"kcOutbox"
#define INBOX_TABLE                     @"kcInbox"



#define INBOX_HASH_KEY_RECEIVER         @"Rcv"
#define INBOX_RANGE_KEY_FILEPATH        @"d#s"


#define OUTBOX_HASH_KEY                 @"Snd"
#define OUTBOX_RANGE_KEY                @"FP"





#define USER_POINTS_TABLE               @"kcPoints"
// Hash key only USERNAME               @"U"


/* attributes */
#define NumberOfSentPhotos                  @"SP"
#define NumberOfReceivedPhotos              @"RP"
#define NumberOfScreenShotsTaken            @"SST"
#define NumberOfScreenShotsTakenByOthers    @"SSTO"
#define NumberOfRevengePointsUsed           @"RPU"

#define NumberOfFollowers                   @"NF"
#define NumberFollowing                     @"FN"




//                     public static final String STATUS 				= "status";




                    /*   Points table  */

#define REVENGE_POINTS_TABLE            @"kcIOU"
#define REVENGE_HASH_KEY                @"U"
#define REVENGE_RANGE_KEY_AGAINST       @"Agnst"
#define REVENGE_POINTS                  @"p"


//#define WALL_OF_SHAME_TABLE             @"kcWOS"
//#define WOS_HASH_KEY                    @"U"
//#define WOS_RANGE_KEY                   @"d#s"


#define CONTACTS_TABLE                   @"kcContacts"
#define CONTACTS_HASH_KEY                @"U"
#define CONTACTS_RANGE_KEY               @"conU"


//#define FEED_TABLE                       @"kcFriendsFeed"
//#define FEED_HASH_KEY                    @"username"
//#define FEED_RANGE_KEY                   @"againstPerson"

                    /*   Notifications Table  */


#define NOTIFICATION_TABLE                       @"kcNotifications"
#define NOTIFICATION_HASH_KEY                    @"U"
#define NOTIFICATION_RANGE_KEY                   @"FP"


        /**************  Server Request Commands & Variables *****************/

#define COMMAND                             @"Command"
        
#define SEND_PHOTO                          @"SendPhoto"
#define SEND_NOTIFICATON                    @"SendNotification"
#define SEARCH_MOBILE                       @"SearchMobile"

#define REQUEST_TO_FOLLOW                   @"RequestToFollow"
#define RESPONSE_TO_FOLLOW                  @"ResponseToFollow"
#define REQUEST_TO_ADD_CONTACT              @"RequestToAddContact"
#define RESPONSE_TO_ADD_CONTACT             @"ResponseToAddContact"

#define REQUEST_MOBILE_CONFIRMATION_CODE    @"RequestMobileCode"
#define VERIFY_MOBILE_CONFIRMATION_CODE     @"VerifyMobileCode"
#define REQUEST_EMAIL_CONFIRMATION_CODE     @"RequestEmailCode"
#define VERIFY_EMAIL_CONFIRMATION_CODE      @"VerifyEmailCode"

#define UPDATE_PERSONAL_INFO                @"UpdatePersonalInfo"
#define CHANGE_PASSWORD                     @"ChangePassword"
#define CHANGE_PREFERENCES                  @"ChangePreferences"


#define GET_CONTACTS_SEARCH_OPTION          @"GetContactsPrivacySetting"
#define GET_MOBILE_SEARCH_OPTION            @"GetMobileSearchOption"

#define CHANGE_CONTACTS_PRIVACY_SETTING     @"ChangeContactsPrivacySetting"
#define CHANGE_MOBILE_PRIVACY_SETTING       @"ChangeMobilePrivacySetting"


#define CONTACT_US                          @"ContactUs"





#define GET_USER_INFO                       @"GetUserInfo"
#define UPDATE_PROFILE_PHOTO                @"UpdateProfilePhoto"

#define USER_IS_ACTIVE_TODAY                @"UserIsActive"

#define GET_ALL_CONTACTS                    @"AllContacts"




#define SCREENSHOT_RESPONSE         @"ScreenshotResponse"
#define GET_CAROUSEL_PHOTOS         @"GetCarouselPhotos"



#define UNSEND_MESSAGE                @"UnsendMessage"





#define CLICKABLE   @"c"

#define UNSEND_KEY   @"unsendKey"




#define OPTION @"Option"



/* SEARCH_MOBILE schema - < user_mobile(hash), contact_mobile [set of address book numbers], username > */
 
#define PersonToFollow          @"personToFollow"


#define CODE            @"code"
#define CONTACTS        @"contacts"


#define HAS_PROFILE_PHOTO        @"HP"




#define ADD     @"add"
#define DELETE  @"delete"



//TODO: change this to request s3 file from server at app launch, incase it ever changes

//Used during registration.
//Directly queries dynamodb to allow users to find if user name already exists
//#define PublicAccessKey                     @"AKIAIDXWVF7IGWOQM3KA"
//#define PublictPassKey                      @"2dkTSbraErkZ1w1pOXTL2b1wiaE+Mmvwur6gUPc+"






#define USERNAME                        @"U"
#define REALNAME                        @"R"
#define MEDIATYPE                       @"MT"


#define RECEIVER                        @"Rcv"
#define RECEIVERS                       @"Rcvs"
#define RECEIVERS_ARRAY                 @"Rcvs_Array"

#define VIEW                            @"View"
#define NOT_VIEWED                      @"No"


#define DATE_SENDER                     @"d#s"
#define SENDER                          @"Snd"

#define FILEPATH                        @"FP"
#define FILENAME                        @"FN"


#define SCREENSHOT_SAFE                 @"ssSafe"

                /***************** CORE DATA *******************/


#define SENT_MESSAGE_TABLE              @"Sent_message"
#define RECEIVED_MESSAGE_TABLE          @"Received_message"
#define CONTACT_USER_TABLE              @"User"

#define USERNAME_LONG                   @"username"


#define NOT_CLICKABLE                   @"NC"

#define NOTICE                          @"notice"


            /* Sent_message */

#define CD_Date         @"date"
#define CD_Filepath     @"filepath"
#define CD_Mediatype    @"mediaType"
#define CD_Message      @"message"
#define CD_Receivers    @"receivers"
#define CD_Sender       @"sender"
#define CD_Status       @"status"

            /* Received_message */

//#define CD_Date         @"date"
//#define CD_Filepath     @"filepath"
//#define CD_Mediatype    @"mediaType"
//#define CD_Message      @"message"
#define CD_DeleteDate     @"delete_date"
#define CD_Delete_Marker  @"delete_marker"
#define CD_From           @"from"
#define CD_ViewStatus     @"view_status"
#define CD_DateSender     @"date_sender"



            /* ViewController_State */

#define CD_ViewControllerName   @"viewControllerName"
#define CD_Time                 @"time"
#define CD_Vaild                @"valid"
#define CD_Action               @"action"
#define CD_ObjectView           @"objectView"
#define CD_Info                 @"info"


            /* User */

#define CD_Data                 @"data"
#define CD_DataType             @"dataType"
#define CD_Email                @"email"
#define CD_Mobile               @"mobile"
#define CD_Realname             @"realname"
#define CD_Username             @"username"








#define MOBILE                          @"mobile"
#define EMAIL                           @"email"

#define DATATYPE                        @"dataType"
#define DATA                            @"data"

#define IV                              @"iv"
#define TIMESTAMP                       @"timestamp"
#define HMAC                            @"hmac"
#define SIGNATURE                       @"signature"
#define HEXSIGN                         @"hex"


#define DATE                            @"date"

#define MESSAGE                         @"message"
#define STATUS                          @"status"

#define PENDING                         @"Pending"
#define SENT                            @"Sent"
#define SENT_L                          @"sent"
#define FAILED                          @"Failed"
#define SomeFriendsGotIt                @"Some friends got it"

#define FailedToSendDoubleTap FAILED //@"Failed to send, tap to try again"


//#define MEDIATYPE                       @"mediaType"
#define MOVIEURL                        @"movieURL"

#define IMAGE                           @"image"
#define VIDEO                           @"video"
#define AUDIO                           @"audio"



#define QPDAY                           @"DAY"
#define QPMONTH                         @"MONTH"
#define QPYEAR                          @"YEAR"
#define QPTIME                          @"TIME"
#define QPHOURS                         @"HOURS"
#define QPMINUTES                       @"MINUTES"

#define QPDATE                          @"DATE"
#define QPFULLDATE                      @"FULLDATE"



#define EMPTY                           @"empty"
#define TEXT                            @"text"

#define NOTIFICATION                    @"notification"
#define SCREENSHOT_NOTIFICATION         @"Screenshot"



enum QPSegmentControlMedia:NSUInteger {
    QPSegmentControlTypeNone,
    QPSegmentControlTypePhoto,
    QPSegmentControlTypeVideo,
    QPSegmentControlTypeAudio
};



enum KCSegmentControlMailbox:NSUInteger {
    KCSegmentControlInbox, // 0
    KCSegmentControlOutbox // 1
};


    
    
    




/* Types sent back from LOGIN server */
#define VALID_OK 			 0
#define USER_ALREADY_EXIST	 1
#define INVALID_USER_NAME 	 2
#define INVALID_PASSWORD 	 3
#define USERNAME_TOO_LONG 	 4
#define USERNAME_TOO_SHORT 	 5
#define PASSWORD_TOO_LONG 	 6
#define PASSWORD_TOO_SHORT   7
#define REGISTER_ERROR 		 8
#define REGISTER_EXCEPTION 	 9
#define USER_DOES_NOT_EXIST  10
#define PARAMATER_MISSING    11
#define UNKNOWN_ERR0R   	 12

    
#define LastInboxMonth @"lastInboxMonth"
#define InboxTableConst @"kcInbox_"


#define PROFILE_IMAGES  @"profile_images"

#define SMALL_IMAGE     @"small_image.jpg"
#define MEDIUM_IMAGE    @"medium_image.jpg"
#define LARGE_IMAGE     @"large_image.jpg"


#define ACTION         @"action"


@interface Constants:NSObject

+(BOOL)setupKwikcyUrl;
+(NSString *)getKwikcyUrl;


+(NSString *)current_month;
+(BOOL)InboxTableMonthMatchesCurrentMonth;
+(NSString *)InboxTableForMonth;

//+(NSString *)getInboxTable;
//+(void)setInboxTableForMonth:(NSString *)month;

//@property (nonatomic, strong) NSString* outbox_table;

//@property (nonatomic, strong)NSString* outb;

//extern NSString *const SENDING_TABLE;
////#define SENDING_TABLE                   @"kcOutbox"
//#define OUTBOX_TABLE

+(UIAlertView *)errorAlert:(NSString *)message;
+(UIAlertView *)expiredCredentialsAlert;
+(UIAlertView *)alertWithTitle:(NSString *)title andMessage:(NSString *)message;


+(UIColor *)getFadedStrawberryColor;
+(UIColor *)getStrawberryColor;
+(UIColor *)getSkyColor;




+(NSString *)getPrefixForUsername:(NSString *)username;

+(void)makeImageRound:(UIImageView *)imageView;

@end

