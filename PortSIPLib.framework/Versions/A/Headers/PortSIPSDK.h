#import <Foundation/Foundation.h>
#import "PortSIPEventDelegate.h"
#import "PortSIPTypes.hxx"
#import "PortSIPErrors.hxx"

/*!
* @author Copyright (c) 2006-2014 PortSIP Solutions,Inc. All rights reserved.
* @version 11.2
* @see http://www.PortSIP.com
* @class PortSIPSDK
* @brief PortSIP VoIP SDK functions class.
 
PortSIP SDK functions class description.
*/
@interface PortSIPSDK : NSObject

@property (nonatomic, weak) id<PortSIPEventDelegate> delegate;

/** @defgroup groupSDK SDK functions
 * SDK functions
 * @{
 */
/** @defgroup group1 Initialize and register functions
 * Initialize and register functions
 * @{
 */

/*!
 * @brief Initialize the SDK.
 *
 * @param transport Transport for SIP signaling.TRANSPORT_PERS is the PortSIP private transport for anti the SIP blocking, it must using with the PERS.
 * @param logLevel Set the application log level, the SDK generate the "PortSIP_Log_datatime.log" file if the log enabled.
 * @param logFilePath   The log file path, the path(folder) MUST is exists.
 * @param maxCallLines  In theory support unlimited lines just depends on the device capability, for SIP client recommend less than 1 - 100;
 * @param sipAgent     The User-Agent header to insert in SIP messages.
 * @param audioDeviceLayer
 *            Specifies which audio device layer should be using:<br>
 *            0 = Use the OS default device.<br>
 *            1 = Virtual device    - Virtual device, usually use this for the device which no sound device installed.<br>
 * @param videoDeviceLayer
 *            Specifies which video device layer should be using:<br>
 *            0 = Use the OS default device.<br>
 *            1 = Use Virtual device, usually use this for the device which no camera installed.
 * @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code
 */
- (int) initialize:(TRANSPORT_TYPE)transport
          loglevel:(PORTSIP_LOG_LEVEL)logLevel
           logPath:(NSString*)logFilePath
           maxLine:(int)maxCallLines
             agent:(NSString*)sipAgent
  audioDeviceLayer:(int)audioDeviceLayer
  videoDeviceLayer:(int)videoDeviceLayer;

/*!
 *  @brief Un-initialize the SDK and release resources.
 */
- (void) unInitialize;

/*!
 *  @brief Set user account info.
 *
 *  @param userName           Account(User name) of the SIP, usually provided by an IP-Telephony service provider.
 *  @param displayName        The display name of user, you can set it as your like, such as "James Kend". It's optional.
 *  @param authName           Authorization user name (usually equals the username).
 *  @param password           The password of user, it's optional.
 *  @param localIP            The local computer IP address to bind (for example: 192.168.1.108), it will be using for send and receive SIP message and RTP packet. If pass this IP as the IPv6 format then the SDK using IPv6.<br>
 *                            If you want the SDK choose correct network interface(IP) automatically, please pass the "0.0.0.0"(for IPv4) or "::"(for IPv6).
 *  @param localSIPPort       The SIP message transport listener port(for example: 5060).
 *  @param userDomain         User domain; this parameter is optional that allow pass a empty string if you are not use domain.
 *  @param sipServer          SIP proxy server IP or domain(for example: xx.xxx.xx.x or sip.xxx.com).
 *  @param sipServerPort      Port of the SIP proxy server, (for example: 5060).
 *  @param stunServer         Stun server, use for NAT traversal, it's optional and can be pass empty string to disable STUN.
 *  @param stunServerPort     STUN server port,it will be ignored if the outboundServer is empty.
 *  @param outboundServer     Outbound proxy server(for example: sip.domain.com), it's optional that allow pass a empty string if not use outbound server.
 *  @param outboundServerPort Outbound proxy server port, it will be ignored if the outboundServer is empty.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int) setUser:(NSString*)userName
    displayName:(NSString*)displayName
       authName:(NSString*)authName
       password:(NSString*)password
        localIP:(NSString*)localIP
   localSIPPort:(int)localSIPPort
     userDomain:(NSString*)userDomain
      SIPServer:(NSString*)sipServer
  SIPServerPort:(int)sipServerPort
     STUNServer:(NSString*)stunServer
 STUNServerPort:(int)stunServerPort
 outboundServer:(NSString*)outboundServer
outboundServerPort:(int)outboundServerPort;

/*!
 *  @brief Register to SIP proxy server(login to server)
 *
 *  @param expires Registration refresh Interval in seconds, maximum is 3600, it will be inserted into SIP REGISTER message headers.
  *  @param retryTimes The retry times if failed to refresh the registration, set to <= 0 the retry will be disabled and onRegisterFailure callback triggered when retry failure.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 *  if register to server succeeded then onRegisterSuccess will be triggered, otherwise onRegisterFailure triggered.
 */
- (int)registerServer:(int)expires
           retryTimes:(int)retryTimes;

/*!
 *  @brief Un-register from the SIP proxy server.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)unRegisterServer;

/*!
 *  @brief Set the license key, must called before setUser function.
 *
 *  @param key The SDK license key, please purchase from PortSIP
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setLicenseKey:(NSString*)key;

/** @} */ // end of group1

/** @defgroup group2 NIC and local IP functions
 * @{
 */

/*!
 *  @brief Get the Network Interface Card numbers.
 *
 *  @return If the function succeeds, the return value is NIC numbers >= 0. If the function fails, the return value is a specific error code.
 */
- (int)getNICNums;

/*!
 *  @brief Get the local IP address by Network Interface Card index.
 *
 *  @param index The IP address index, for example, the PC has two NICs, we want to obtain the second NIC IP, then set this parameter 1. The first NIC IP index is 0.
 *
 *  @return The buffer that to receives the IP.
 */
- (NSString*)getLocalIpAddress:(int)index;

/** @} */ // end of group2

/** @defgroup group3 Audio and video codecs functions
 * @{
 */

/*!
 *  @brief Enable an audio codec, it will be appears in SDP.
 *
 *  @param codecType Audio codec type.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)addAudioCodec:(AUDIOCODEC_TYPE)codecType;

/*!
 *  @brief Enable a video codec, it will be appears in SDP.
 *
 *  @param codecType Video codec type.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)addVideoCodec:(VIDEOCODEC_TYPE)codecType;

/*!
 *  @brief Detect enabled audio codecs is empty or not.
 *
 *  @return If no audio codec was enabled the return value is true, otherwise is false.
 */
- (BOOL)isAudioCodecEmpty;

/*!
 *  @brief Detect enabled video codecs is empty or not.
 *
 *  @return If no video codec was enabled the return value is true, otherwise is false.
 */
- (BOOL)isVideoCodecEmpty;

/*!
 *  @brief Set the RTP payload type for dynamic audio codec.
 *
 *  @param codecType   Audio codec type, defined in the PortSIPTypes file.
 *  @param payloadType The new RTP payload type that you want to set.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setAudioCodecPayloadType:(AUDIOCODEC_TYPE)codecType
                    payloadType:(int) payloadType;

/*!
 *  @brief Set the RTP payload type for dynamic Video codec.
 *
 *  @param codecType   Video codec type, defined in the PortSIPTypes file.
 *  @param payloadType The new RTP payload type that you want to set.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setVideoCodecPayloadType:(VIDEOCODEC_TYPE)codecType
                    payloadType:(int) payloadType;

/*!
 *  @brief Remove all enabled audio codecs.
 */
- (void)clearAudioCodec;

/*!
 *  @brief Remove all enabled video codecs.
 */
- (void)clearVideoCodec;

/*!
 *  @brief Set the codec parameter for audio codec.
 *
 *  @param codecType Audio codec type, defined in the PortSIPTypes file.
 *  @param parameter The parameter in string format.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 @remark Example:
 @code [myVoIPsdk setAudioCodecParameter:AUDIOCODEC_AMR parameter:"mode-set=0; octet-align=1; robust-sorting=0"]; @endcode
 */
- (int)setAudioCodecParameter:(AUDIOCODEC_TYPE)codecType
                     parameter:(NSString*)parameter;

/*!
 *  @brief Set the codec parameter for video codec.
 *
 *  @param codecType Video codec type, defined in the PortSIPTypes file.
 *  @param parameter The parameter in string format.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 @remark Example:
 @code [myVoIPsdk setVideoCodecParameter:VIDEOCODEC_H264 parameter:"profile-level-id=420033; packetization-mode=0"]; @endcode
 */
- (int)setVideoCodecParameter:(VIDEOCODEC_TYPE) codecType
                     parameter:(NSString*)parameter;

/** @} */ // end of group3

/** @defgroup group4 Additional setting functions
 * @{
 */

/*!
 *  @brief Set user display name.
 *
 *  @param displayName The display name.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setDisplayName:(NSString*)displayName;

/*!
 *  @brief Get the current version number of the SDK.
 *
 *  @param majorVersion Return the major version number.
 *  @param minorVersion Return the minor version number.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)getVersion:(int*)majorVersion minorVersion:(int*)minorVersion;

/*!
 *  @brief Enable/disable PRACK.
 *
 *  @param enable enable Set to true to enable the SDK support PRACK, default the PRACK is disabled.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)enableReliableProvisional:(BOOL)enable;

/*!
 *  @brief Enable/disable the 3Gpp tags, include "ims.icsi.mmtel" and "g.3gpp.smsip".
 *
 *  @param enable enable Set to true to enable the SDK support 3Gpp tags.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)enable3GppTags:(BOOL)enable;

/*!
 *  @brief Enable/disable callback the sending SIP messages.
 *
 *  @param enable enable Set as true to enable callback the sent SIP messages, false to disable. Once enabled,the "onSendingSignaling" event will be fired once the SDK sending a SIP message.
 */
- (void)enableCallbackSendingSignaling:(BOOL)enable;

/*!
 *  @brief Set the SRTP policy.
 *
 *  @param srtpPolicy The SRTP policy.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setSrtpPolicy:(SRTP_POLICY)srtpPolicy;

/*!
 *  @brief Set the RTP ports range for audio and video streaming.
 *
 *  @param minimumRtpAudioPort The minimum RTP port for audio stream.
 *  @param maximumRtpAudioPort The maximum RTP port for audio stream.
 *  @param minimumRtpVideoPort The minimum RTP port for video stream.
 *  @param maximumRtpVideoPort The maximum RTP port for video stream.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 *  @remark
 *  The port range((max - min) % maxCallLines) should more than 4.
 */
- (int)setRtpPortRange:(int) minimumRtpAudioPort
   maximumRtpAudioPort:(int) maximumRtpAudioPort
   minimumRtpVideoPort:(int) minimumRtpVideoPort
   maximumRtpVideoPort:(int) maximumRtpVideoPort;

/*!
 *  @brief Set the RTCP ports range for audio and video streaming.
 *
 *  @param minimumRtcpAudioPort The minimum RTCP port for audio stream.
 *  @param maximumRtcpAudioPort The maximum RTCP port for audio stream.
 *  @param minimumRtcpVideoPort The minimum RTCP port for video stream.
 *  @param maximumRtcpVideoPort The maximum RTCP port for video stream.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 *  @remark
 *  The port range((max - min) % maxCallLines) should more than 4.
 */
- (int)setRtcpPortRange:(int) minimumRtcpAudioPort
   maximumRtcpAudioPort:(int) maximumRtcpAudioPort
   minimumRtcpVideoPort:(int) minimumRtcpVideoPort
   maximumRtcpVideoPort:(int) maximumRtcpVideoPort;

/*!
 *  @brief Enable call forward.
 *
 *  @param forBusyOnly If set this parameter as true, the SDK will forward all incoming calls when currently it's busy. If set this as false, the SDK forward all inconing calls anyway.
 *  @param forwardTo   The call forward target, it's must likes sip:xxxx@sip.portsip.com.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)enableCallForward:(BOOL)forBusyOnly forwardTo:(NSString*) forwardTo;

/*!
 *  @brief Disable the call forward, the SDK is not forward any incoming call after this function is called.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)disableCallForward;

/*!
 *  @brief Allows to periodically refresh Session Initiation Protocol (SIP) sessions by sending repeated INVITE requests.
 *
 *  @param timerSeconds The value of the refresh interval in seconds. Minimum requires 90 seconds.
 *  @param refreshMode  Allow set the session refresh by UAC or UAS: SESSION_REFERESH_UAC or SESSION_REFERESH_UAS;
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 *  @remark The repeated INVITE requests, or re-INVITEs, are sent during an active call leg to allow user agents (UA) or proxies to determine the status of a SIP session.
 *  Without this keepalive mechanism, proxies that remember incoming and outgoing requests (stateful proxies) may continue to retain call state needlessly.
 *  If a UA fails to send a BYE message at the end of a session or if the BYE message is lost because of network problems, a stateful proxy does not know that the session has ended.
 *  The re-INVITES ensure that active sessions stay active and completed sessions are terminated.
 */
- (int)enableSessionTimer:(int) timerSeconds refreshMode:(SESSION_REFRESH_MODE)refreshMode;

/*!
 *  @brief Disable the session timer.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)disableSessionTimer;

/*!
 *  @brief Enable the "Do not disturb" to enable/disable.
 *
 *  @param state If set to true, the SDK reject all incoming calls anyway.
 */
- (void)setDoNotDisturb:(BOOL)state;

/*!
 *  @brief Use to obtain the MWI status.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)detectMwi;

/*!
 *  @brief Allows enable/disable the check MWI(Message Waiting Indication).
 *
 *  @param state If set as true will check MWI automatically once successfully registered to a SIP proxy server.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)enableCheckMwi:(BOOL)state;

/*!
 *  @brief Enable or disable send RTP keep-alive packet during the call is established.
 *
 *  @param state                Set to true allow send the keep-alive packet during the conversation.
 *  @param keepAlivePayloadType The payload type of the keep-alive RTP packet, usually set to 126.
 *  @param deltaTransmitTimeMS  The keep-alive RTP packet send interval, in millisecond, usually recommend 15000 - 300000.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setRtpKeepAlive:(BOOL)state
  keepAlivePayloadType:(int)keepAlivePayloadType
   deltaTransmitTimeMS:(int)deltaTransmitTimeMS;

/*!
 *  @brief Enable or disable send SIP keep-alive packet.
 *
 *  @param keepAliveTime This is the SIP keep alive time interval in seconds, set to 0 to disable the SIP keep alive, it's in seconds, recommend 30 or 50.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setKeepAliveTime:(int) keepAliveTime;
/*!
 *  @brief Set the audio capture sample.
 *
 *  @param ptime    It's should be a multiple of 10, and between 10 - 60(included 10 and 60).
 *  @param maxPtime For the "maxptime" attribute, should be a multiple of 10, and between 10 - 60(included 10 and 60). Can't less than "ptime".
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 *  @remark which will be appears in the SDP of INVITE and 200 OK message as "ptime and "maxptime" attribute.
 */
- (int)setAudioSamples:(int) ptime
              maxPtime:(int) maxPtime;

/*!
 *  @brief Set the SDK receive the SIP message that include special mime type.
 *
 *  @param methodName  Method name of the SIP message, likes INVITE, OPTION, INFO, MESSAGE, UPDATE, ACK etc. More details please read the RFC3261.
 *  @param mimeType    The mime type of SIP message.
 *  @param subMimeType The sub mime type of SIP message.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 *@remarks
 * Default, the PortSIP VoIP SDK support these media types(mime types) that in the below incoming SIP messages:
 * @code
 "message/sipfrag" in NOTIFY message.
 "application/simple-message-summary" in NOTIFY message.
 "text/plain" in MESSAGE message.
 "application/dtmf-relay" in INFO message.
 "application/media_control+xml" in INFO message.
 * @endcode
 * The SDK allows received SIP message that included above mime types. Now if remote side send a INFO
 * SIP message, this message "Content-Type" header value is "text/plain", the SDK will reject this INFO message,
 * because "text/plain" of INFO message does not included in the default support list.
 * Then how to let the SDK receive the SIP INFO message that included "text/plain" mime type? We should use
 * addSupportedMimyType to do it:
 * @code
[myVoIPSdk addSupportedMimeType:@"INFO" mimeType:@"text" subMimeType:@"plain"];
 * @endcode
 * If want to receive the NOTIFY message with "application/media_control+xml", then:
 *@code
 [myVoIPSdk addSupportedMimeType:@"NOTIFY" mimeType:@"application" subMimeType:@"media_control+xml"];
 * @endcode
 * About the mime type details, please visit this website: http://www.iana.org/assignments/media-types/
 */
- (int)addSupportedMimeType:(NSString*) methodName
                   mimeType:(NSString*) mimeType
                subMimeType:(NSString*) subMimeType;

/** @} */ // end of group4

/** @defgroup group5 Access SIP message header functions
 * @{
 */

/*!
 *  @brief Access the SIP header of SIP message.
 
 *
 *  @param sipMessage        The SIP message.
 *  @param headerName        Which header want to access of the SIP message.
 *
 *  @return If the function succeeds, the return value is headerValue. If the function fails, the return value is nil.
 * @remark
 * When got a SIP message in the onReceivedSignaling callback event, and want to get SIP message header value, use getExtensionHeaderValue to do it:
 * @code
 NSString* headerValue = [myVoIPSdk getExtensionHeaderValue:message headerName:name];
 * @endcode
 */
-(NSString*)getExtensionHeaderValue:(NSString*)sipMessage
                    headerName:(NSString*) headerName;

/*!
 *  @brief Add the extension header(custom header) into every outgoing SIP message.
 *
 *  @param headerName  The custom header name which will be appears in every outgoing SIP message.
 *  @param headerValue The custom header value.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)addExtensionHeader:(NSString*) headerName
              headerValue:(NSString*) headerValue;

/*!
 *  @brief Clear the added extension headers(custom headers)
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 @remark
 @code
 Example, we have added two custom headers into every outgoing SIP message and want remove them.
 [myVoIPSdk addExtensionHeader:@"Blling" headerValue:@"usd100.00"];
 [myVoIPSdk addExtensionHeader:@"ServiceId" headerValue:@"8873456"];
 [myVoIPSdk clearAddextensionHeaders];
 @endcode
 */
- (int)clearAddExtensionHeaders;

/*!
 *  @brief Modify the special SIP header value for every outgoing SIP message.
 *
 *  @param headerName  The SIP header name which will be modify it's value.
 *  @param headerValue The heaver value want to modify.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)modifyHeaderValue:(NSString*) headerName
             headerValue:(NSString*) headerValue;
/*!
 *  @brief Clear the modify headers value, no longer modify every outgoing SIP message header values.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 @remark  Example, modified two headers value for every outging SIP message and then clear it:
 @code
 
 [myVoIPSdk modifyHeaderValue:@"Expires" headerValue:@"1000");
 [myVoIPSdk modifyHeaderValue:@"User-Agent", headerValue:@"MyTest Softphone 1.0");
 [myVoIPSdk cleaModifyHeaders];
 @endcode
 */
- (int)clearModifyHeaders;

/** @} */ // end of group5

/** @defgroup group6 Audio and video functions
 * @{
 */

/*!
 *  @brief Set the video device that will use for video call.
 *
 *  @param deviceId Device ID(index) for video device(camera).
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setVideoDeviceId:(int) deviceId;

/*!
 *  @brief Set the video capture resolution.
 *
 *  @param resolution Video resolution, defined in PortSIPType file. Note: Some cameras don't support SVGA and XVGA, 720P, please read your camera manual.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setVideoResolution:(VIDEO_RESOLUTION)resolution;

/*!
 *  @brief Set the audio bit rate.
 *
 *  @param sessionId The session ID of the call.
 *  @param codecType Audio codec type.
 *  @param bitrateKbps The video bit rate in KBPS.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setAudioBitrate:(long) sessionId
             codecType:(AUDIOCODEC_TYPE)codecType
           bitrateKbps:(int)bitrateKbps;

/*!
 *  @brief Set the video bit rate.
 *
 *  @param bitrateKbps The video bit rate in KBPS.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setVideoBitrate:(int) bitrateKbps;

/*!
 *  @brief Set the video frame rate. 
 *
 *  @param frameRate The frame rate value, minimum is 5, maximum is 30. The bigger value will give you better video quality but require more bandwidth.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 *  @remark Usually you do not need to call this function set the frame rate, the SDK using default frame rate.
 */
- (int)setVideoFrameRate:(int) frameRate;

/*!
 *  @brief Send the video to remote side.
 *
 *  @param sessionId The session ID of the call.
 *  @param sendState Set to true to send the video, false to stop send.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)sendVideo:(long)sessionId
       sendState:(BOOL)sendState;

/*!
 *  @brief Changing the orientation of the video.
 *
 *  @param rotation  The video rotation that you want to set(0,90,180,270).
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setVideoOrientation:(int) rotation;


/*!
 *  @brief Set the the window that using to display the local video image.
 *
 *  @param localVideoWindow The UIView to display local video image from camera.
 */
- (void)setLocalVideoWindow:(UIView*)localVideoWindow;

/*!
 *  @brief Set the window for a session that using to display the received remote video image.
 *
 *  @param sessionId         The session ID of the call.
 *  @param remoteVideoWindow The UIView to display received remote video image.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setRemoteVideoWindow:(long) sessionId
          remoteVideoWindow:(UIView*) remoteVideoWindow;

/*!
 *  @brief Start/stop to display the local video image.
 *
 *  @param state state Set to true to display local video iamge.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)displayLocalVideo:(BOOL) state;

/*!
 *  @brief Enable/disable the NACK feature(rfc6642) which help to improve the video quatliy.
 *
 *  @param state state Set to true to enable.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setVideoNackStatus:(BOOL) state;

/*!
 *  @brief Mute the device microphone.it's unavailable for Android and iOS.
 *
 *  @param mute If the value is set to true, the microphone is muted, set to false to un-mute it.
 */
- (void)muteMicrophone:(BOOL) mute;

/*!
 *  @brief Mute the device speaker, it's unavailable for Android and iOS.
 *
 *  @param mute If the value is set to true, the speaker is muted, set to false to un-mute it.
 */
- (void)muteSpeaker:(BOOL) mute;

/*!
 *  @brief Set the audio device that will use for audio call. 
 *
 *  @param enable Set to true the SDK use loudspeaker for audio call, this just available for mobile platform only.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 *  @remark Just allow switch between earphone and Loudspeaker.
 */
- (int)setLoudspeakerStatus:(BOOL)enable;


/*!
 *  @brief Obtain the dynamic microphone volume level from current call. 
 *
 *  @param speakerVolume    Return the dynamic speaker volume by this parameter, the range is 0 - 9.
 *  @param microphoneVolume Return the dynamic microphone volume by this parameter, the range is 0 - 9.
 *  @remark Usually set a timer to call this function to refresh the volume level indicator.
 */
- (void)getDynamicVolumeLevel:(int *) speakerVolume
             microphoneVolume:(int *) microphoneVolume;//(0-10)

/** @} */ // end of group6

/** @defgroup group7 Call functions
 * @{
 */

/*!
 *  @brief Make a call
 *
 *  @param callee    The callee, it can be name only or full SIP URI, for example: user001 or sip:user001@sip.iptel.org or sip:user002@sip.yourdomain.com:5068
 *  @param sendSdp   If set to false then the outgoing call doesn't include the SDP in INVITE message.
 *  @param videoCall If set the true and at least one video codec was added, then the outgoing call include the video codec into SDP.
 *
 *  @return If the function succeeds, the return value is the session ID of the call greater than 0. If the function fails, the return value is a specific error code. Note: the function success just means the outgoing call is processing, you need to detect the call final state in onInviteTrying, onInviteRinging, onInviteFailure callback events.
 */
- (long)call:(NSString*) callee
     sendSdp:(BOOL)sendSdp
   videoCall:(BOOL)videoCall;

/*!
 *  @brief rejectCall Reject the incoming call.
 *
 *  @param sessionId The sessionId of the call.
 *  @param code      Reject code, for example, 486, 480 etc.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)rejectCall:(long)sessionId code:(int)code;

/*!
 *  @brief hangUp Hang up the call.
 *
 *  @param sessionId Session ID of the call.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)hangUp:(long)sessionId;

/*!
 *  @brief answerCall Answer the incoming call.
 *
 *  @param sessionId The session ID of call.
 *  @param videoCall If the incoming call is a video call and the video codec is matched, set to true to answer the video call.<br>If set to false, the answer call doesn't include video codec answer anyway.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)answerCall:(long)sessionId videoCall:(BOOL)videoCall;

/*!
 *  @brief Use the re-INVITE to update the established call.
 *  @param sessionId   The session ID of call.
 *  @param enableAudio Set to true to allow the audio in update call, false for disable audio in update call.
 *  @param enableVideo Set to true to allow the video in update call, false for disable video in update call.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 @remark
 Example usage:<br>

 Example 1: A called B with the audio only, B answered A, there has an audio conversation between A, B. Now A want to see B video,
 A use these functions to do it.
 @code
 [myVoIPSdk clearVideoCodec];
 [myVoIPSdk addVideoCodec:VIDEOCODEC_H264];
 [myVoIPSdk updateCall:sessionId enableAudio:true enableVideo:true];
 @endcode
 Example 2: Remove video stream from currently conversation.
 @code
 [myVoIPSdk updateCall:sessionId enableAudio:true enableVideo:false];
 @endcode
 */
- (int)updateCall:(long)sessionId
      enableAudio:(BOOL)enableAudio
      enableVideo:(BOOL)enableVideo;

/*!
 *  @brief To place a call on hold.
 *
 *  @param sessionId The session ID of call.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)hold:(long)sessionId;

/*!
 *  @brief Take off hold.
 *
 *  @param sessionId The session ID of call.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)unHold:(long)sessionId;

/*!
 *  @brief Mute the specified session audio or video.
 *
 *  @param sessionId         The session ID of the call.
 *  @param muteIncomingAudio Set it to true to mute incoming audio stredam, can't hearing remote side audio.
 *  @param muteOutgoingAudio Set it to true to mute outgoing audio stredam, the remote side can't hearing audio.
 *  @param muteIncomingVideo Set it to true to mute incoming video stredam, can't see remote side video.
 *  @param muteOutgoingVideo Set it to true to mute outgoing video stredam, the remote side can't see video.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)muteSession:(long)sessionId
 muteIncomingAudio:(BOOL)muteIncomingAudio
 muteOutgoingAudio:(BOOL)muteOutgoingAudio
 muteIncomingVideo:(BOOL)muteIncomingVideo
 muteOutgoingVideo:(BOOL)muteOutgoingVideo;

/*!
 *  @brief Forward call to another one when received the incoming call.
 *
 *  @param sessionId The session ID of the call.
 *  @param forwardTo Target of the forward, it can be "sip:number@sipserver.com" or "number" only.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)forwardCall:(long)sessionId forwardTo:(NSString*) forwardTo;

/*!
 *  @brief Send DTMF tone.
 *
 *  @param sessionId    The session ID of the call.
 *  @param dtmfMethod   Support send DTMF tone with two methods: DTMF_RFC2833 and DTMF_INFO. The DTMF_RFC2833 is recommend.
 *  @param code         The DTMF tone(0-16).
 * <p><table>
 * <tr><th>code</th><th>Description</th></tr>
 * <tr><td>0</td><td>The DTMF tone 0.</td></tr><tr><td>1</td><td>The DTMF tone 1.</td></tr><tr><td>2</td><td>The DTMF tone 2.</td></tr>
 * <tr><td>3</td><td>The DTMF tone 3.</td></tr><tr><td>4</td><td>The DTMF tone 4.</td></tr><tr><td>5</td><td>The DTMF tone 5.</td></tr>
 * <tr><td>6</td><td>The DTMF tone 6.</td></tr><tr><td>7</td><td>The DTMF tone 7.</td></tr><tr><td>8</td><td>The DTMF tone 8.</td></tr>
 * <tr><td>9</td><td>The DTMF tone 9.</td></tr><tr><td>10</td><td>The DTMF tone *.</td></tr><tr><td>11</td><td>The DTMF tone #.</td></tr>
 * <tr><td>12</td><td>The DTMF tone A.</td></tr><tr><td>13</td><td>The DTMF tone B.</td></tr><tr><td>14</td><td>The DTMF tone C.</td></tr>
 * <tr><td>15</td><td>The DTMF tone D.</td></tr><tr><td>16</td><td>The DTMF tone FLASH.</td></tr>
 * </table></p>
 *  @param dtmfDuration The DTMF tone samples, recommend 160.
 *  @param playDtmfTone Set to true the SDK play local DTMF tone sound during send DTMF.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)sendDtmf:(long) sessionId
     dtmfMethod:(DTMF_METHOD) dtmfMethod
           code:(int) code
    dtmfDration:(int) dtmfDuration
   playDtmfTone:(BOOL) playDtmfTone;

/** @} */ // end of group7

/** @defgroup group8 Refer functions
 * @{
 */

/*!
 *  @brief Refer the currently call to another one.<br>
 *  @param sessionId The session ID of the call.
 *  @param referTo   Target of the refer, it can be "sip:number@sipserver.com" or "number" only.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 *  @remark
 @code
  	[myVoIPSdk refer:sessionId  referTo:@"sip:testuser12@sip.portsip.com"];
 @endcode
 You can download the demo AVI at:
 "http://www.portsip.com/downloads/video/blindtransfer.rar", use the Windows Media
 Player to play the AVI file after extracted, it will shows how to do the transfer.
 */
- (int)refer:(long)sessionId referTo:(NSString*)referTo;

/*!
 *  @brief  Make an attended refer.
 *
 *  @param sessionId        The session ID of the call.
 *  @param replaceSessionId Session ID of the replace call.
 *  @param referTo          Target of the refer, it can be "sip:number@sipserver.com" or "number" only.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 *  @remark
 Please read the sample project source code to got more details. Or download the demo AVI at:"http://www.portsip.com/downloads/video/blindtransfer.rar"<br>
 use the Windows Media Player to play the AVI file after extracted, it will shows how to do the transfer.
 */
- (int)attendedRefer:(long)sessionId
    replaceSessionId:(long)replaceSessionId
             referTo:(NSString*)  referTo;

/*!
 *  @brief Accept the REFER request, a new call will be make if called this function, usuall called after onReceivedRefer callback event.
 *
 *  @param referId        The ID of REFER request that comes from onReceivedRefer callback event.
 *  @param referSignaling The SIP message of REFER request that comes from onReceivedRefer callback event.
 *
 *  @return If the function succeeds, the return value is a session ID greater than 0 to the new call for REFER, otherwise is a specific error code less than 0.
 */
- (long)acceptRefer:(long)referId referSignaling:(NSString*) referSignaling;

/*!
 *  @brief Reject the REFER request.
 *
 *  @param referId The ID of REFER request that comes from onReceivedRefer callback event.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)rejectRefer:(long)referId;

/** @} */ // end of group8

/** @defgroup group9 Send audio and video stream functions
 * @{
 */

/*!
 *  @brief Enable the SDK send PCM stream data to remote side from another source to instread of microphone.
 *
 *  @param sessionId           The session ID of call.
 *  @param state               Set to true to enable the send stream, false to disable.
 *  @param streamSamplesPerSec The PCM stream data sample in seconds, for example: 8000 or 16000.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 *  @remark MUST called this function first if want to send the PCM stream data to another side.
 */
- (int)enableSendPcmStreamToRemote:(long)sessionId state:(BOOL)state streamSamplesPerSec:(int)streamSamplesPerSec;

/*!
 *  @brief Send the audio stream in PCM format from another source to instead of audio device capture(microphone).
 *
 *  @param sessionId Session ID of the call conversation.
 *  @param data      The PCM audio stream data, must is 16bit, mono.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 *  @remark Usually we should use it like below:
 *  @code
 [myVoIPSdk enableSendPcmStreamToRemote:sessionId state:YES streamSamplesPerSec:16000];
 [myVoIPSdk sendPcmStreamToRemote:sessionId data:data];
 *  @endcode
 */
- (int)sendPcmStreamToRemote:(long)sessionId data:(NSData*) data;

/*!
 *  @brief Enable the SDK send video stream data to remote side from another source to instead of camera.
 *
 *  @param sessionId The session ID of call.
 *  @param state     Set to true to enable the send stream, false to disable.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)enableSendVideoStreamToRemote:(long)sessionId state:(BOOL)state;

/*!
 *  @brief Send the video stream to remote
 *
 *  @param sessionId Session ID of the call conversation.
 *  @param data      The video video stream data, must is i420 format.
 *  @param width     The video image width.
 *  @param height    The video image height.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 *  @remark  Send the video stream in i420 from another source to instead of video device capture(camera).<br>
 Before called this function,you MUST call the enableSendVideoStreamToRemote function.<br>
 Usually we should use it like below:
 @code
 [myVoIPSdk enableSendVideoStreamToRemote:sessionId state:YES];
 [myVoIPSdk sendVideoStreamToRemote:sessionId data:data width:352 height:288];
 @endcode
 */
- (int)sendVideoStreamToRemote:(long)sessionId data:(NSData*) data width:(int)width height:(int)height;

/** @} */ // end of group9

/** @defgroup group10 RTP packets, Audio stream and video stream callback functions
 * @{
 */

/*!
 *  @brief Set the RTP callbacks to allow access the sending and received RTP packets.
 *
 *  @param enable Set to true to enable the RTP callback for received and sending RTP packets, the onSendingRtpPacket and onReceivedRtpPacket events will be triggered.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setRtpCallback:(BOOL)enable;

/*!
 *  @brief Enable/disable the audio stream callback
 *
 *  @param sessionId    The session ID of call.
 *  @param enable       Set to true to enable audio stream callback, false to stop the callback.
 *  @param callbackMode The audio stream callback mode
 * <p><table>
 * <tr><th>Type</th><th>Description</th></tr>
 * <tr><td>AUDIOSTREAM_LOCAL_MIX</td><td>Callback the audio stream from microphone for all channels.  </td></tr>
 * <tr><td>AUDIOSTREAM_LOCAL_PER_CHANNEL</td><td>Callback the audio stream from microphone for one channel base on the given sessionId. </td></tr>
 * <tr><td>AUDIOSTREAM_REMOTE_MIX</td><td>Callback the received audio stream that mixed including all channels. </td></tr>
 * <tr><td>AUDIOSTREAM_REMOTE_PER_CHANNEL</td><td>Callback the received audio stream for one channel base on the given sessionId.</td></tr>
 * </table></p>
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 *  @remark the onAudioRawCallback event will be triggered if the callback is enabled.
 */
- (int)enableAudioStreamCallback:(long) sessionId  enable:(BOOL)enable callbackMode:(AUDIOSTREAM_CALLBACK_MODE)callbackMode;

/*!
 *  @brief Enable/disable the video stream callback.
 *
 *  @param sessionId    The session ID of call.
 *  @param callbackMode The video stream callback mode.
 * <p><table>
 * <tr><th>Mode</th><th>Description</th></tr>
 * <tr><td>VIDEOSTREAM_NONE</td><td>Disable video stream callback. </td></tr>
 * <tr><td>VIDEOSTREAM_LOCAL</td><td>Local video stream callback. </td></tr>
 * <tr><td>VIDEOSTREAM_REMOTE</td><td>Remote video stream callback. </td></tr>
 * <tr><td>VIDEOSTREAM_BOTH</td><td>Both of local and remote video stream callback. </td></tr>
 * </table></p>
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 *  @remark the onVideoRawCallback event will be triggered if the callback is enabled.
 */
- (int)enableVideoStreamCallback:(long) sessionId callbackMode:(VIDEOSTREAM_CALLBACK_MODE) callbackMode;

/** @} */ // end of group10

/** @defgroup group11 Record functions
 * @{
 */

/*!
 *  @brief Start record the call.
 *
 *  @param sessionId        The session ID of call conversation.
 *  @param recordFilePath   The file path to save record file, it's must exists.
 *  @param recordFileName   The file name of record file, for example: audiorecord.wav or videorecord.avi.
 *  @param appendTimeStamp  Set to true to append the timestamp to the recording file name.
 *  @param audioFileFormat  The audio record file format.
 *  @param audioRecordMode  The audio record mode.
 *  @param aviFileCodecType The codec which using for compress the video data to save into video record file.
 *  @param videoRecordMode  Allow set video record mode, support record received video/send video/both received and send.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)startRecord:(long)sessionId
    recordFilePath:(NSString*) recordFilePath
    recordFileName:(NSString*) recordFileName
   appendTimeStamp:(BOOL)appendTimeStamp
   audioFileFormat:(AUDIO_FILE_FORMAT) audioFileFormat
   audioRecordMode:(RECORD_MODE) audioRecordMode
  aviFileCodecType:(VIDEOCODEC_TYPE) aviFileCodecType
   videoRecordMode:(RECORD_MODE) videoRecordMode;

/*!
 *  @brief Stop record.
 *
 *  @param sessionId The session ID of call conversation.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)stopRecord:(long)sessionId;

/** @} */ // end of group11

/** @defgroup group12 Play audio and video file to remoe functions
 * @{
 */


/*!
 *  @brief Play an AVI file to remote party.
 *
 *  @param sessionId Session ID of the call.
 *  @param aviFile   The file full path name, such as "/test.avi".
 *  @param loop      Set to false to stop play video file when it is end. Set to true to play it as repeat.
 *  @param playAudio If set to true then play audio and video together, set to false just play video only.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int) playVideoFileToRemote:(long)sessionId aviFile:(NSString*) aviFile loop:(BOOL)loop playAudio:(BOOL)playAudio;

/*!
 *  @brief Stop play video file to remote side.
 *
 *  @param sessionId Session ID of the call.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)stopPlayVideoFileToRemote:(long)sessionId;

/*!
 *  @brief Play an wave file to remote party.
 *
 *  @param sessionId         Session ID of the call.
 *  @param filename          The file full path name, such as "/test.wav".
 *  @param fileSamplesPerSec The wave file sample in seconds, should be 8000 or 16000 or 32000.
 *  @param loop              Set to false to stop play audio file when it is end. Set to true to play it as repeat.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)playAudioFileToRemote:(long)sessionId
                    filename:(NSString*) filename // Support .wav, .amr and .pcm file formats
           fileSamplesPerSec:(int) fileSamplesPerSec // Must set fileSamplesPerSec for play .pcm file
                        loop:(BOOL)loop;

/*!
 *  @brief Stop play wave file to remote side.
 *
 *  @param sessionId Session ID of the call.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)stopPlayAudioFileToRemote:(long)sessionId;

/*!
 *  @brief Play an wave file to remote party as conversation background sound.
 *
 *  @param sessionId         Session ID of the call.
 *  @param filename          The file full path name, such as "/test.wav".
 *  @param fileSamplesPerSec The wave file sample in seconds, should be 8000 or 16000 or 32000.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)playAudioFileToRemoteAsBackground:(long)sessionId filename:(NSString*)filename fileSamplesPerSec:(int)fileSamplesPerSec;

/*!
 *  @brief Stop play an wave file to remote party as conversation background sound.
 *
 *  @param sessionId Session ID of the call.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)stopPlayAudioFileToRemoteAsBackground:(long)sessionId;

/** @} */ // end of group12

/** @defgroup group13 Conference functions
 * @{
 */

/*!
 *  @brief Create a conference. It's failures if the exists conference isn't destroy yet.
 *
 *  @param conferenceVideoWindow         The UIView which using to display the conference video.
 *  @param videoResolution               The conference video resolution.
 *  @param displayLocalVideoInConference Display the local video on video window or not. 
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)createConference:(UIView*) conferenceVideoWindow
        videoResolution:(VIDEO_RESOLUTION) videoResolution
      displayLocalVideo:(BOOL)displayLocalVideoInConference;

/*!
 *  @brief Destroy the exist conference.
 */
- (void)destroyConference;

/*!
 *  @brief Set the window for a conference that using to display the received remote video image.
 *
 *  @param conferenceVideoWindow The UIView which using to display the conference video.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setConferenceVideoWindow:(UIView*) conferenceVideoWindow;

/*!
 *  @brief Join a session into exist conference, if the call is in hold, please un-hold first.
 *
 *  @param sessionId Session ID of the call.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)joinToConference:(long)sessionId;

/*!
 *  @brief Remove a session from an exist conference.
 *
 *  @param sessionId Session ID of the call.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)removeFromConference:(long)sessionId;

/** @} */ // end of group13

/** @defgroup group14 RTP and RTCP QOS functions
 * @{
 */

/*!
 *  @brief Set the audio RTCP bandwidth parameters as the RFC3556.
 *
 *  @param sessionId The session ID of call conversation.
 *  @param BitsRR    The bits for the RR parameter.
 *  @param BitsRS    The bits for the RS parameter.
 *  @param KBitsAS   The Kbits for the AS parameter.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setAudioRtcpBandwidth:(long)sessionId
                      BitsRR:(int)BitsRR
                      BitsRS:(int)BitsRS
                     KBitsAS:(int)KBitsAS;

/*!
 *  @brief Set the video RTCP bandwidth parameters as the RFC3556.
 *
 *  @param sessionId The session ID of call conversation.
 *  @param BitsRR    The bits for the RR parameter.
 *  @param BitsRS    The bits for the RS parameter.
 *  @param KBitsAS   The Kbits for the AS parameter.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setVideoRtcpBandwidth:(long)sessionId
                      BitsRR:(int)BitsRR
                      BitsRS:(int)BitsRS
                     KBitsAS:(int)KBitsAS;

/*!
 *  @brief Set the DSCP(differentiated services code point) value of QoS(Quality of Service) for audio channel.
 *
 *  @param enable    Set to true to enable audio QoS.
 *  @param DSCPValue  The six-bit DSCP value. Valid range is 0-63. As defined in RFC 2472, the DSCP value is the high-order 6 bits of the IP version 4 (IPv4) TOS field and the IP version 6 (IPv6) Traffic Class field.
 *  @param priority  The 802.1p priority(PCP) field in a 802.1Q/VLAN tag. Values 0-7 set the priority, value -1 leaves the priority setting unchanged.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setAudioQos:(BOOL)enable DSCPValue:(int)DSCPValue priority:(int)priority;

/*!
 *  @brief Set the DSCP(differentiated services code point) value of QoS(Quality of Service) for video channel.
 *
 *  @param enable    Set as true to enable QoS, false to disable.
 *  @param DSCPValue The six-bit DSCP value. Valid range is 0-63. As defined in RFC 2472, the DSCP value is the high-order 6 bits of the IP version 4 (IPv4) TOS field and the IP version 6 (IPv6) Traffic Class field.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)setVideoQos:(BOOL)enable DSCPValue:(int)DSCPValue;

/** @} */ // end of group14

/** @defgroup group15 RTP statistics functions
 * @{
 */

/*!
 *  @brief Get the "in-call" statistics. The statistics are reset after the query.
 *
 *  @param sessionId             The session ID of call conversation.
 *  @param currentBufferSize     Current jitter buffer size in ms.
 *  @param preferredBufferSize   Preferred buffer size in ms.
 *  @param currentPacketLossRate Loss rate (network + late) in percent.
 *  @param currentDiscardRate    Late loss rate in percent.
 *  @param currentExpandRate     Fraction (of original stream) of synthesized speech inserted through expansion.
 *  @param currentPreemptiveRate Fraction of synthesized speech inserted through pre-emptive expansion.
 *  @param currentAccelerateRate fraction of data removed through acceleration through acceleration.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)getNetworkStatistics:(long)sessionId
          currentBufferSize:(int *)currentBufferSize
        preferredBufferSize:(int *) preferredBufferSize
      currentPacketLossRate:(int *)currentPacketLossRate
         currentDiscardRate:(int *)currentDiscardRate
          currentExpandRate:(int *)currentExpandRate
      currentPreemptiveRate:(int *)currentPreemptiveRate
      currentAccelerateRate:(int *)currentAccelerateRate;

/*!
 *  @brief Obtain the RTP statisics of audio channel.
 *
 *  @param sessionId        The session ID of call conversation.
 *  @param averageJitterMs  Short-time average jitter (in milliseconds).
 *  @param maxJitterMs      Maximum short-time jitter (in milliseconds).
 *  @param discardedPackets The number of discarded packets on a channel during the call.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)getAudioRtpStatistics:(long)sessionId
             averageJitterMs:(int*)averageJitterMs
                 maxJitterMs:(int*)maxJitterMs
            discardedPackets:(int*)discardedPackets;

/*!
 *  @brief Obtain the RTCP statisics of audio channel.
 *
 *  @param sessionId          The session ID of call conversation.
 *  @param bytesSent          The number of sent bytes.
 *  @param packetsSent        The number of sent packets.
 *  @param bytesReceived      The number of received bytes.
 *  @param packetsReceived    The number of received packets.
 *  @param sendFractionLost   Fraction of sent lost in percent.
 *  @param sendCumulativeLost The number of sent cumulative lost packet.
 *  @param recvFractionLost   Fraction of received lost in percent.
 *  @param recvCumulativeLost The number of received cumulative lost packets.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)getAudioRtcpStatistics:(long)sessionId
                    bytesSent:(int*)bytesSent
                  packetsSent:(int*)packetsSent
                bytesReceived:(int*)bytesReceived
              packetsReceived:(int*)packetsReceived
             sendFractionLost:(int*)sendFractionLost
           sendCumulativeLost:(int*)sendCumulativeLost
             recvFractionLost:(int*)recvFractionLost
           recvCumulativeLost:(int*)recvCumulativeLost;

/*!
 *  @brief Obtain the RTP statisics of video.
 *
 *  @param sessionId       The session ID of call conversation.
 *  @param bytesSent       The number of sent bytes.
 *  @param packetsSent     The number of sent packets.
 *  @param bytesReceived   The number of received bytes.
 *  @param packetsReceived The number of received packets.
 *
 *  @return  If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)getVideoRtpStatistics:(long)sessionId
                   bytesSent:(int*)bytesSent
                 packetsSent:(int*)packetsSent
               bytesReceived: (int*)bytesReceived
             packetsReceived:(int*)packetsReceived;

/** @} */ // end of group15

/** @defgroup group16 Audio effect functions
 * @{
 */

/*!
 *  @brief Enable/disable Voice Activity Detection(VAD).
 *
 *  @param state Set to true to enable VAD, false to disable.
 */
- (void)enableVAD:(BOOL)state;

/*!
 *  @brief Enable/disable AEC (Acoustic Echo Cancellation).
 *
 *  @param state AEC type, default is EC_NONE.
 */
- (void)enableAEC:(EC_MODES)state;

/*!
 *  @brief Enable/disable Comfort Noise Generator(CNG).
 *
 *  @param state state Set to true to enable CNG, false to disable.
 */
- (void)enableCNG:(BOOL)state;

/*!
 *  @brief Enable/disable Automatic Gain Control(AGC).
 *
 *  @param state AGC type, default is AGC_NONE.
 */
- (void)enableAGC:(AGC_MODES)state;

/*!
 *  @brief Enable/disable Audio Noise Suppression(ANS).
 *
 *  @param state NS type, default is NS_NONE.
 */
- (void)enableANS:(NS_MODES)state;

/** @} */ // end of group16

/** @defgroup group17 Send OPTIONS/INFO/MESSAGE functions
 * @{
 */

/*!
 *  @brief Send OPTIONS message.
 *
 *  @param to  The receiver of OPTIONS message.
 *  @param sdp The SDP of OPTIONS message, it's optional if don't want send the SDP with OPTIONS message.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)sendOptions:(NSString*)to sdp:(NSString*) sdp;

/*!
 *  @brief Send a INFO message to remote side in dialog.
 *
 *  @param sessionId    The session ID of call.
 *  @param mimeType     The mime type of INFO message.
 *  @param subMimeType  The sub mime type of INFO message.
 *  @param infoContents The contents that send with INFO message.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)sendInfo:(long)sessionId
       mimeType:(NSString*) mimeType
    subMimeType:(NSString*) subMimeType
   infoContents:(NSString*) infoContents;

/*!
 *  @brief Send a MESSAGE message to remote side in dialog.
 
 
 
 *
 *  @param sessionId     The session ID of the call.
 *  @param mimeType      The mime type of MESSAGE message.
 *  @param subMimeType   The sub mime type of MESSAGE message.
 *  @param message       The contents which send with MESSAGE message, allow binary data.
 *  @param messageLength The message size.
 *
 *  @return If the function succeeds, the return value is a message ID allows track the message send state in onSendMessageSuccess and onSendMessageFailure. If the function fails, the return value is a specific error code less than 0.
 *  @remark
 *  Example 1: send a plain text message. Note: to send other languages text, please use the UTF8 to encode the message before send.
 *  @code
	[myVoIPsdk sendMessage:sessionId mimeType:@"text" subMimeType:@"plain" message:data messageLength:dataLen];
 *  @endcode
 *  Example 2: send a binary message.
 *  @code
	[myVoIPsdk sendMessage:sessionId mimeType:@"application" subMimeType:@"vnd.3gpp.sms" message:data messageLength:dataLen];
 *  @endcode
 */
- (long)sendMessage:(long)sessionId
           mimeType:(NSString*) mimeType
        subMimeType:(NSString*)subMimeType
            message:(NSData*) message
      messageLength:(int)messageLength;

/*!
 *  @brief Send a out of dialog MESSAGE message to remote side.
 
 
 
 *
 *  @param to            The message receiver. Likes sip:receiver@portsip.com
 *  @param mimeType      The mime type of MESSAGE message.
 *  @param subMimeType   The sub mime type of MESSAGE message.
 *  @param message       The contents which send with MESSAGE message, allow binary data.
 *  @param messageLength The message size.
 *
 *  @return If the function succeeds, the return value is a message ID allows track the message send state in onSendOutOfMessageSuccess and onSendOutOfMessageFailure.  If the function fails, the return value is a specific error code less than 0.
 * @remark
 * Example 1: send a plain text message. Note: to send other languages text, please use the UTF8 to encode the message before send.
 * @code
		[myVoIPsdk sendOutOfDialogMessage:@"sip:user1@sip.portsip.com" mimeType:@"text" subMimeType:@"plain" message:data messageLength:dataLen];
 * @endcode
 * Example 2: send a binary message.
 * @code
		[myVoIPsdk sendOutOfDialogMessage:@"sip:user1@sip.portsip.com" mimeType:@"application" subMimeType:@"vnd.3gpp.sms" message:data messageLength:dataLen];
 * @endcode
 */
- (long)sendOutOfDialogMessage:(NSString*) to
                      mimeType:(NSString*) mimeType
                   subMimeType:(NSString*)subMimeType
                       message:(NSData*) message
                 messageLength:(int)messageLength;

/** @} */ // end of group17

/** @defgroup group18 Presence functions
 * @{
 */

/*!
 *  @brief Send a SUBSCRIBE message for presence to a contact.
 *
 *  @param contact The target contact, it must likes sip:contact001@sip.portsip.com.
 *  @param subject This subject text will be insert into the SUBSCRIBE message. For example: "Hello, I'm Jason".<br>
 The subject maybe is UTF8 format, you should use UTF8 to decode it.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)presenceSubscribeContact:(NSString*) contact
                        subject:(NSString*) subject;

/*!
 *  @brief Accept the presence SUBSCRIBE request which received from contact.
 *
 *  @param subscribeId Subscribe id, when received a SUBSCRIBE request from contact, the event onPresenceRecvSubscribe will be triggered,the event inclues the subscribe id.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)presenceAcceptSubscribe:(long)subscribeId;

/*!
 *  @brief Reject a presence SUBSCRIBE request which received from contact.
 *
 *  @param subscribeId Subscribe id, when received a SUBSCRIBE request from contact, the event onPresenceRecvSubscribe will be triggered,the event inclues the subscribe id.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)presenceRejectSubscribe:(long)subscribeId;

/*!
 *  @brief Send a NOTIFY message to contact to notify that presence status is online/changed.
 *
 *  @param subscribeId Subscribe id, when received a SUBSCRIBE request from contact, the event onPresenceRecvSubscribe will be triggered,the event inclues the subscribe id.
 *  @param statusText  The state text of presende online, for example: "I'm here"
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)presenceOnline:(long)subscribeId
           statusText:(NSString*) statusText;

/*!
 *  @brief Send a NOTIFY message to contact to notify that presence status is offline.
 *
 *  @param subscribeId Subscribe id, when received a SUBSCRIBE request from contact, the event onPresenceRecvSubscribe will be triggered,the event inclues the subscribe id.
 *
 *  @return If the function succeeds, the return value is 0. If the function fails, the return value is a specific error code.
 */
- (int)presenceOffline:(long)subscribeId;










//////////////////////////////////////////////////////////////////////////
//
// Device Manage functions.
//
//////////////////////////////////////////////////////////////////////////
/* NOT SUPPORTED YET
- (int)getNumOfVideoCaptureDevices;
- (int)getVideoCaptureDeviceName:(int) index
                        uniqueId:(NSString*)uniqueIdUTF8
                  uniqueIdLength:(int) uniqueIdUTF8Length
                      deviceName:(NSString*) deviceNameUTF8
                deviceNameLength:(int) deviceNameUTF8Length;


- (int)getNumOfRecordingDevices;
- (int)getNumOfPlayoutDevices;

- (int)getRecordingDeviceName:(int) index deviceName:(NSString*)nameUTF8 deviceNameUTF8Length:(int)nameUTF8Length;
- (int)getPlayoutDeviceName:(int) index deviceName:(NSString*)nameUTF8 deviceNameUTF8Length:(int)nameUTF8Length;

- (int)setSpeakerVolume:(int) volume;
- (int)getSpeakerVolume;

- (int)setSystemOutputMute:(BOOL)enable;
- (BOOL)getSystemOutputMute;

- (int)setMicVolume:(int) volume;
- (int)getMicVolume;
- (int)setSystemInputMute:(BOOL)enable;
- (BOOL)getSystemInputMute;
- (void)audioPlayLoopbackTest:(BOOL)enable;
//*/

/** @} */ // end of group18

/** @defgroup group19 Keep awake functions
 * @{
 */


/*!
 * @brief Keep VoIP awake in the background
   @discussion If you want your application can receive the incoming call when it run in background, you should call this function in applicationDidEnterBackground.
 *
 *  @return If the function succeeds, the return value is true. If the function fails, the return value is false. 
 */
- (BOOL) startKeepAwake;//call in applicationDidEnterBackground

/*!
 *  @brief Keep VoIP awake in the background
    @discussion Call this function in applicationWillEnterForeground once your application come back to foreground.
 *
 *  @return If the function succeeds, the return value is true. If the function fails, the return value is false.
 */
- (BOOL) stopKeepAwake;//call in applicationWillEnterForeground

/** @} */ // end of group19
/** @} */ // end of groupSDK

@end
