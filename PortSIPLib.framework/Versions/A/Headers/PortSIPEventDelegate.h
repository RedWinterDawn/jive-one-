/*!
 * @author Copyright (c) 2006-2014 PortSIP Solutions,Inc. All rights reserved.
 * @version 11.2
 * @see http://www.PortSIP.com
 * @brief PortSIP SDK Callback events Delegate.
 
 PortSIP SDK Callback events Delegate description.
 */
#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#endif



@protocol PortSIPEventDelegate <NSObject>
@required
/** @defgroup groupDelegate SDK Callback events
 * SDK Callback events
 * @{
 */
/** @defgroup group21 Register events
 * Register events
 * @{
 */

/*!
 *  When successfully register to server, this event will be triggered.
 *
 *  @param statusText The status text.
 *  @param statusCode The status code.
 */
- (void)onRegisterSuccess:(char*) statusText statusCode:(int)statusCode;

/*!
 *  If register to SIP server is fail, this event will be triggered.
 *
 *  @param statusText The status text.
 *  @param statusCode The status code.
 */
- (void)onRegisterFailure:(char*) statusText statusCode:(int)statusCode;

/** @} */ // end of group21

/** @defgroup group22 Call events
 * @{
 */

/*!
 *  When the call is coming, this event was triggered.
 *
 *  @param sessionId         The session ID of the call.
 *  @param callerDisplayName The display name of caller
 *  @param caller            The caller.
 *  @param calleeDisplayName The display name of callee.
 *  @param callee            The callee.
 *  @param audioCodecs       The matched audio codecs, it's separated by "#" if have more than one codec.
 *  @param videoCodecs       The matched video codecs, it's separated by "#" if have more than one codec.
 *  @param existsAudio       If it's true means this call include the audio.
 *  @param existsVideo       If it's true means this call include the video.
 */
- (void)onInviteIncoming:(long)sessionId
       callerDisplayName:(char*)callerDisplayName
                  caller:(char*)caller
       calleeDisplayName:(char*)calleeDisplayName
                  callee:(char*)callee
             audioCodecs:(char*)audioCodecs
             videoCodecs:(char*)videoCodecs
             existsAudio:(BOOL)existsAudio
             existsVideo:(BOOL)existsVideo;

@optional
/*!
 *  If the outgoing call was processing, this event triggered.
 *
 *  @param sessionId The session ID of the call.
 */
- (void)onInviteTrying:(long)sessionId;

/*!
 *  Once the caller received the "183 session progress" message, this event will be triggered.
 *
 *  @param sessionId        The session ID of the call.
 *  @param audioCodecs      The matched audio codecs, it's separated by "#" if have more than one codec.
 *  @param videoCodecs      The matched video codecs, it's separated by "#" if have more than one codec.
 *  @param existsEarlyMedia If it's true means the call has early media.
 *  @param existsAudio      If it's true means this call include the audio.
 *  @param existsVideo      If it's true means this call include the video.
 */
- (void)onInviteSessionProgress:(long)sessionId
                    audioCodecs:(char*)audioCodecs
                    videoCodecs:(char*)videoCodecs
               existsEarlyMedia:(BOOL)existsEarlyMedia
                    existsAudio:(BOOL)existsAudio
                    existsVideo:(BOOL)existsVideo;

/*!
 *  If the out going call was ringing, this event triggered.
 *
 *  @param sessionId  The session ID of the call.
 *  @param statusText The status text.
 *  @param statusCode The status code.
 */
- (void)onInviteRinging:(long)sessionId
             statusText:(char*)statusText
             statusCode:(int)statusCode;

/*!
 *  If the remote party was answered the call, this event triggered.
 *
 *  @param sessionId         The session ID of the call.
 *  @param callerDisplayName The display name of caller
 *  @param caller            The caller.
 *  @param calleeDisplayName The display name of callee.
 *  @param callee            The callee.
 *  @param audioCodecs       The matched audio codecs, it's separated by "#" if have more than one codec.
 *  @param videoCodecs       The matched video codecs, it's separated by "#" if have more than one codec.
 *  @param existsAudio       If it's true means this call include the audio.
 *  @param existsVideo       If it's true means this call include the video.
 */
- (void)onInviteAnswered:(long)sessionId
       callerDisplayName:(char*)callerDisplayName
                  caller:(char*)caller
       calleeDisplayName:(char*)calleeDisplayName
                  callee:(char*)callee
             audioCodecs:(char*)audioCodecs
             videoCodecs:(char*)videoCodecs
             existsAudio:(BOOL)existsAudio
             existsVideo:(BOOL)existsVideo;

/*!
 *  If the outgoing call is fails, this event triggered.
 *
 *  @param sessionId The session ID of the call.
 *  @param reason    The failure reason.
 *  @param code      The failure code.
 */
- (void)onInviteFailure:(long)sessionId
                 reason:(char*)reason
                   code:(int)code;

/*!
 *  This event will be triggered when remote party updated this call.
 *
 *  @param sessionId   The session ID of the call.
 *  @param audioCodecs The matched audio codecs, it's separated by "#" if have more than one codec.
 *  @param videoCodecs The matched video codecs, it's separated by "#" if have more than one codec.
 *  @param existsAudio If it's true means this call include the audio.
 *  @param existsVideo If it's true means this call include the video.
 */
- (void)onInviteUpdated:(long)sessionId
                    audioCodecs:(char*)audioCodecs
                    videoCodecs:(char*)videoCodecs
                    existsAudio:(BOOL)existsAudio
                    existsVideo:(BOOL)existsVideo;

/*!
 *  This event will be triggered when UAC sent/UAS received ACK(the call is connected). Some functions(hold, updateCall etc...) can called only after the call connected, otherwise the functions will return error.
 *
 *  @param sessionId The session ID of the call.
 */
- (void)onInviteConnected:(long)sessionId;

/*!
 *  If the enableCallForward method is called and a call is incoming, the call will be forwarded automatically and trigger this event.
 *
 *  @param forwardTo The forward target SIP URI.
 */
- (void)onInviteBeginingForward:(char*)forwardTo;

/*!
 *  This event is triggered once remote side close the call.
 *
 *  @param sessionId The session ID of the call.
 */
- (void)onInviteClosed:(long)sessionId;

/*!
 *  If the remote side has placed the call on hold, this event triggered.
 *
 *  @param sessionId The session ID of the call.
 */
- (void)onRemoteHold:(long)sessionId;

/*!
 *  If the remote side was un-hold the call, this event triggered
 *
 *  @param sessionId   The session ID of the call.
 *  @param audioCodecs The matched audio codecs, it's separated by "#" if have more than one codec.
 *  @param videoCodecs The matched video codecs, it's separated by "#" if have more than one codec.
 *  @param existsAudio If it's true means this call include the audio.
 *  @param existsVideo If it's true means this call include the video.
 */
- (void)onRemoteUnHold:(long)sessionId
           audioCodecs:(char*)audioCodecs
           videoCodecs:(char*)videoCodecs
           existsAudio:(BOOL)existsAudio
           existsVideo:(BOOL)existsVideo;

/** @} */ // end of group22

/** @defgroup group23 Refer events
 * @{
 */

/*!
 *  This event will be triggered once received a REFER message.
 *
 *  @param sessionId       The session ID of the call.
 *  @param referId         The ID of the REFER message, pass it to acceptRefer or rejectRefer
 *  @param to              The refer target.
 *  @param from            The sender of REFER message.
 *  @param referSipMessage The SIP message of "REFER", pass it to "acceptRefer" function.
 */
- (void)onReceivedRefer:(long)sessionId
                referId:(long)referId
                     to:(char*)to
                   from:(char*)from
        referSipMessage:(char*)referSipMessage;

/*!
 *  This callback will be triggered once remote side called "acceptRefer" to accept the REFER
 *
 *  @param sessionId The session ID of the call.
 */
- (void)onReferAccepted:(long)sessionId;

/*!
 *  This callback will be triggered once remote side called "rejectRefer" to reject the REFER
 *
 *  @param sessionId The session ID of the call.
 *  @param reason    Reject reason.
 *  @param code      Reject code.
 */
- (void)onReferRejected:(long)sessionId reason:(char*)reason code:(int)code;

/*!
 *  When the refer call is processing, this event trigged.
 *
 *  @param sessionId The session ID of the call.
 */
- (void)onTransferTrying:(long)sessionId;

/*!
 *  When the refer call is ringing, this event trigged.
 *
 *  @param sessionId The session ID of the call.
 */
- (void)onTransferRinging:(long)sessionId;

/*!
 *  When the refer call is succeeds, this event will be triggered. The ACTV means Active.
    For example: A established the call with B, A transfer B to C, C accepted the refer call, A received this event.
 *
 *  @param sessionId The session ID of the call.
 */
- (void)onACTVTransferSuccess:(long)sessionId;

/*!
 *  When the refer call is fails, this event will be triggered. The ACTV means Active.
 For example: A established the call with B, A transfer B to C, C rejected this refer call, A will received this event.
 *
 *  @param sessionId The session ID of the call.
 *  @param reason    The error reason.
 *  @param code      The error code.
 */
- (void)onACTVTransferFailure:(long)sessionId reason:(char*)reason code:(int)code;

/** @} */ // end of group23

/** @defgroup group24 Signaling events
 * @{
 */
/*!
 *  This event will be triggered when received a SIP message.
 *
 *  @param sessionId The session ID of the call.
 *  @param message   The SIP message which is received.
 */
- (void)onReceivedSignaling:(long)sessionId message:(char*)message;

/*!
 *  This event will be triggered when sent a SIP message.
 *
 *  @param sessionId The session ID of the call.
 *  @param message   The SIP message which is sent.
 */
- (void)onSendingSignaling:(long)sessionId message:(char*)message;

/** @} */ // end of group24

/** @defgroup group25 MWI events
 * @{
 */

/*!
 *  If has the waiting voice message(MWI), then this event will be triggered.
 *
 *  @param messageAccount        Voice message account
 *  @param urgentNewMessageCount Urgent new message count.
 *  @param urgentOldMessageCount Urgent old message count.
 *  @param newMessageCount       New message count.
 *  @param oldMessageCount       Old message count.
 */
- (void)onWaitingVoiceMessage:(char*)messageAccount
        urgentNewMessageCount:(int)urgentNewMessageCount
        urgentOldMessageCount:(int)urgentOldMessageCount
              newMessageCount:(int)newMessageCount
              oldMessageCount:(int)oldMessageCount;

/*!
 *  If has the waiting fax message(MWI), then this event will be triggered.
 *
 *  @param messageAccount        Fax message account
 *  @param urgentNewMessageCount Urgent new message count.
 *  @param urgentOldMessageCount Urgent old message count.
 *  @param newMessageCount       New message count.
 *  @param oldMessageCount       Old message count.
 */
- (void)onWaitingFaxMessage:(char*)messageAccount
        urgentNewMessageCount:(int)urgentNewMessageCount
        urgentOldMessageCount:(int)urgentOldMessageCount
              newMessageCount:(int)newMessageCount
              oldMessageCount:(int)oldMessageCount;

/** @} */ // end of group25

/** @defgroup group26 DTMF events
 * @{
 */

/*!
 *  This event will be triggered when received a DTMF tone from remote side.
 *
 *  @param sessionId The session ID of the call.
 *  @param tone      Dtmf tone.
 * <p><table>
 * <tr><th>code</th><th>Description</th></tr>
 * <tr><td>0</td><td>The DTMF tone 0.</td></tr><tr><td>1</td><td>The DTMF tone 1.</td></tr><tr><td>2</td><td>The DTMF tone 2.</td></tr>
 * <tr><td>3</td><td>The DTMF tone 3.</td></tr><tr><td>4</td><td>The DTMF tone 4.</td></tr><tr><td>5</td><td>The DTMF tone 5.</td></tr>
 * <tr><td>6</td><td>The DTMF tone 6.</td></tr><tr><td>7</td><td>The DTMF tone 7.</td></tr><tr><td>8</td><td>The DTMF tone 8.</td></tr>
 * <tr><td>9</td><td>The DTMF tone 9.</td></tr><tr><td>10</td><td>The DTMF tone *.</td></tr><tr><td>11</td><td>The DTMF tone #.</td></tr>
 * <tr><td>12</td><td>The DTMF tone A.</td></tr><tr><td>13</td><td>The DTMF tone B.</td></tr><tr><td>14</td><td>The DTMF tone C.</td></tr>
 * <tr><td>15</td><td>The DTMF tone D.</td></tr><tr><td>16</td><td>The DTMF tone FLASH.</td></tr>
 * </table></p>
 */
- (void)onRecvDtmfTone:(long)sessionId tone:(int)tone;

/** @} */ // end of group26

/** @defgroup group27 INFO/OPTIONS message events
 * @{
 */

/*!
 *  This event will be triggered when received the OPTIONS message.
 *
 *  @param optionsMessage The received whole OPTIONS message in text format.
 */
- (void)onRecvOptions:(char*)optionsMessage;

/*!
 *  This event will be triggered when received the INFO message.
 *
 *  @param infoMessage The received whole INFO message in text format.
 */
- (void)onRecvInfo:(char*)infoMessage;

/** @} */ // end of group27

/** @defgroup group28 Presence events
 * @{
 */
/*!
 *  This event will be triggered when received the SUBSCRIBE request from a contact.
 *
 *  @param subscribeId     The id of SUBSCRIBE request.
 *  @param fromDisplayName The display name of contact.
 *  @param from            The contact who send the SUBSCRIBE request.
 *  @param subject         The subject of the SUBSCRIBE request.
 */
- (void)onPresenceRecvSubscribe:(long)subscribeId
                fromDisplayName:(char*)fromDisplayName
                           from:(char*)from
                        subject:(char*)subject;

/*!
 *  When the contact is online or changed presence status, this event will be triggered.
 *
 *  @param fromDisplayName The display name of contact.
 *  @param from            The contact who send the SUBSCRIBE request.
 *  @param stateText       The presence status text.
 */
- (void)onPresenceOnline:(char*)fromDisplayName
                    from:(char*)from
               stateText:(char*)stateText;

/*!
 *  When the contact is went offline then this event will be triggered.
 *
 *  @param fromDisplayName The display name of contact.
 *  @param from            The contact who send the SUBSCRIBE request
 */
- (void)onPresenceOffline:(char*)fromDisplayName from:(char*)from;

/** @} */ // end of group28

/** @defgroup group29 MESSAGE message events
 * @{
 */

/*!
 *  This event will be triggered when received a MESSAGE message in dialog.
 *
 *  @param sessionId         The session ID of the call.
 *  @param mimeType          The message mime type.
 *  @param subMimeType       The message sub mime type.
 *  @param messageData       The received message body, it's can be text or binary data.
 *  @param messageDataLength The length of "messageData".
 */
- (void)onRecvMessage:(long)sessionId
             mimeType:(char*)mimeType
          subMimeType:(char*)subMimeType
          messageData:(unsigned char*)messageData
    messageDataLength:(int)messageDataLength;

/*!
 *  This event will be triggered when received a MESSAGE message out of dialog, for example: pager message.
 *
 *  @param fromDisplayName   The display name of sender.
 *  @param from              The message sender.
 *  @param toDisplayName     The display name of receiver.
 *  @param to                The receiver.
 *  @param mimeType          The message mime type.
 *  @param subMimeType       The message sub mime type.
 *  @param messageData       The received message body, it's can be text or binary data.
 *  @param messageDataLength The length of "messageData".
 */
- (void)onRecvOutOfDialogMessage:(char*)fromDisplayName
                            from:(char*)from
                   toDisplayName:(char*)toDisplayName
                              to:(char*)to
                        mimeType:(char*)mimeType
                     subMimeType:(char*)subMimeType
                     messageData:(unsigned char*)messageData
               messageDataLength:(int)messageDataLength;

/*!
 *  If the message was sent succeeded in dialog, this event will be triggered.
 *
 *  @param sessionId The session ID of the call.
 *  @param messageId The message ID, it's equals the return value of sendMessage function.
 */
- (void)onSendMessageSuccess:(long)sessionId messageId:(long)messageId;

/*!
 *  If the message was sent failure out of dialog, this event will be triggered.
 *
 *  @param sessionId The session ID of the call.
 *  @param messageId The message ID, it's equals the return value of sendMessage function.
 *  @param reason    The failure reason.
 *  @param code      Failure code.
 */
- (void)onSendMessageFailure:(long)sessionId messageId:(long)messageId reason:(char*)reason code:(int)code;

/*!
 *  If the message was sent succeeded out of dialog, this event will be triggered.
 *
 *  @param messageId       The message ID, it's equals the return value of SendOutOfDialogMessage function.
 *  @param fromDisplayName The display name of message sender.
 *  @param from            The message sender.
 *  @param toDisplayName   The display name of message receiver.
 *  @param to              The message receiver.
 */
- (void)onSendOutOfDialogMessageSuccess:(long)messageId
                        fromDisplayName:(char*)fromDisplayName
                                   from:(char*)from
                          toDisplayName:(char*)toDisplayName
                                     to:(char*)to;

/*!
 *  If the message was sent failure out of dialog, this event will be triggered.
 *
 *  @param messageId       The message ID, it's equals the return value of SendOutOfDialogMessage function.
 *  @param fromDisplayName The display name of message sender
 *  @param from            The message sender.
 *  @param toDisplayName   The display name of message receiver.
 *  @param to              The message receiver.
 *  @param reason          The failure reason.
 *  @param code            The failure code.
 */
- (void)onSendOutOfDialogMessageFailure:(long)messageId
                        fromDisplayName:(char*)fromDisplayName
                                   from:(char*)from
                          toDisplayName:(char*)toDisplayName
                                     to:(char*)to
                                 reason:(char*)reason
                                   code:(int)code;

/** @} */ // end of group29

/** @defgroup group30 Play audio and video file finished events
 * @{
 */

/*!
 *  If called playAudioFileToRemote function with no loop mode, this event will be triggered once the file play finished.
 *
 *  @param sessionId The session ID of the call.
 *  @param fileName  The play file name.
 */
- (void)onPlayAudioFileFinished:(long)sessionId fileName:(char*)fileName;

/*!
 *  If called playVideoFileToRemote function with no loop mode, this event will be triggered once the file play finished.
 *
 *  @param sessionId The session ID of the call.
 */
- (void)onPlayVideoFileFinished:(long)sessionId;

/** @} */ // end of group30

/** @defgroup group31 RTP callback events
 * @{
 */
/*!
 *  If called setRTPCallback function to enabled the RTP callback, this event will be triggered once received a RTP packet.
 *
 *  @param sessionId  The session ID of the call.
 *  @param isAudio    If the received RTP packet is of audio, this parameter is true, otherwise false.
 *  @param RTPPacket  The memory of whole RTP packet.
 *  @param packetSize The size of received RTP Packet.
  @note Don't call any SDK API functions in this event directly. If you want to call the API functions or other code which will spend long time, you should post a message to another thread and execute SDK API functions or other code in another thread.
 */
- (void)onReceivedRTPPacket:(long)sessionId isAudio:(BOOL)isAudio RTPPacket:(unsigned char *)RTPPacket packetSize:(int)packetSize;

/*!
 *  If called setRTPCallback function to enabled the RTP callback, this event will be triggered once sending a RTP packet.
 *
 *  @param sessionId  The session ID of the call.
 *  @param isAudio    If the received RTP packet is of audio, this parameter is true, otherwise false.
 *  @param RTPPacket  The memory of whole RTP packet.
 *  @param packetSize The size of received RTP Packet.
  @note Don't call any SDK API functions in this event directly. If you want to call the API functions or other code which will spend long time, you should post a message to another thread and execute SDK API functions or other code in another thread.
 */
- (void)onSendingRTPPacket:(long)sessionId isAudio:(BOOL)isAudio RTPPacket:(unsigned char *)RTPPacket packetSize:(int)packetSize;

/** @} */ // end of group31

/** @defgroup group32 Audio and video stream callback events
* @{
*/

/*!
 *  This event will be triggered once received the audio packets if called enableAudioStreamCallback function.
 *
 *  @param sessionId         The session ID of the call.
 *  @param audioCallbackMode TThe type which pasdded in enableAudioStreamCallback function.
 *  @param data              The memory of audio stream, it's PCM format.
 *  @param dataLength        The data size.
 *  @param samplingFreqHz    The audio stream sample in HZ, for example, it's 8000 or 16000.
  @note Don't call any SDK API functions in this event directly. If you want to call the API functions or other code which will spend long time, you should post a message to another thread and execute SDK API functions or other code in another thread.
 */
- (void)onAudioRawCallback:(long)sessionId
         audioCallbackMode:(int)audioCallbackMode
                      data:(unsigned char *)data
                dataLength:(int)dataLength
            samplingFreqHz:(int)samplingFreqHz;

/*!
 *  This event will be triggered once received the video packets if called enableVideoStreamCallback function.
 *
 *  @param sessionId         The session ID of the call.
 *  @param videoCallbackMode The type which pasdded in enableVideoStreamCallback function.
 *  @param width             The width of video image.
 *  @param height            The height of video image.
 *  @param data              The memory of video stream, it's YUV420 format, YV12.
 *  @param dataLength        The data size.
  @note Don't call any SDK API functions in this event directly. If you want to call the API functions or other code which will spend long time, you should post a message to another thread and execute SDK API functions or other code in another thread.
 */
- (void)onVideoRawCallback:(long)sessionId
         videoCallbackMode:(int)videoCallbackMode
                     width:(int)width
                    height:(int)height
                      data:(unsigned char *)data
                dataLength:(int)dataLength;
/** @} */ // end of group32
/** @} */ // end of groupDelegate
@end

 



