/*
    PortSIP Solutions, Inc.
    Copyright (C) 2006 - 2014 PortSIP Solutions, Inc.
   
    support@portsip.com

    Visit us at http://www.portsip.com
*/



#ifndef PORTSIP_TYPES_hxx
#define PORTSIP_TYPES_hxx


#ifndef __APPLE__
namespace PortSIP
{
#endif


/// Audio codec type
typedef enum
{
	AUDIOCODEC_NONE		= -1,	
	AUDIOCODEC_G729		= 18,	///< G729 8KHZ 8kbit/s
	AUDIOCODEC_PCMA		= 8,	///< PCMA/G711 A-law 8KHZ 64kbit/s
	AUDIOCODEC_PCMU		= 0,	///< PCMU/G711 ��-law 8KHZ 64kbit/s
	AUDIOCODEC_GSM		= 3,	///< GSM 8KHZ 13kbit/s
	AUDIOCODEC_G722		= 9,	///< G722 16KHZ 64kbit/s
	AUDIOCODEC_ILBC		= 97,	///< iLBC 8KHZ 30ms-13kbit/s 20 ms-15kbit/s
	AUDIOCODEC_AMR		= 98,	///< Adaptive Multi-Rate (AMR) 8KHZ (4.75,5.15,5.90,6.70,7.40,7.95,10.20,12.20)kbit/s
	AUDIOCODEC_AMRWB	= 99,	///< Adaptive Multi-Rate Wideband (AMR-WB)16KHZ (6.60,8.85,12.65,14.25,15.85,18.25,19.85,23.05,23.85)kbit/s
	AUDIOCODEC_SPEEX	= 100,	///< SPEEX 8KHZ (2-24)kbit/s
	AUDIOCODEC_SPEEXWB	= 102,	///< SPEEX 16KHZ (4-42)kbit/s
	AUDIOCODEC_ISACWB	= 103,	///< internet Speech Audio Codec(iSAC) 16KHZ (32-54)kbit/s
	AUDIOCODEC_ISACSWB	= 104,	///< internet Speech Audio Codec(iSAC) 16KHZ (32-160)kbit/s
	AUDIOCODEC_G7221	= 121,	///< G722.1 16KHZ (16,24,32)kbit/s
	AUDIOCODEC_OPUS		= 105,	///< OPUS 48KHZ 32kbit/s
	AUDIOCODEC_DTMF		= 101	///< DTMF RFC 2833
}AUDIOCODEC_TYPE;



/// Video codec type
typedef enum
{
	VIDEO_CODE_NONE				= -1,	///< Not use Video codec
	VIDEO_CODEC_I420			= 113,	///< I420/YUV420 Raw Video format, just use with startRecord 
	VIDEO_CODEC_H263			= 34,	///< H263 video codec
	VIDEO_CODEC_H263_1998		= 115,	///< H263+/H263 1998 video codec
	VIDEO_CODEC_H264			= 125,	///< H264 video codec
	VIDEO_CODEC_VP8				= 120	///< VP8 video code
}VIDEOCODEC_TYPE;


/// Video Resolution
typedef enum
{
	VIDEO_NONE	=	0,	
	VIDEO_QCIF	=	1,		///<	176X144		- for H.263, H.263-1998, H.264, VP8
	VIDEO_CIF	=	2,		///<	352X288		- for H.263, H.263-1998, H.264, VP8
	VIDEO_VGA	=	3,		///<	640X480		- for H.264, VP8
	VIDEO_SVGA	=	4,		///<	800X600		- for H.264, VP8
	VIDEO_XVGA	=	5,		///<	1024X768	- for H.264, VP8
	VIDEO_720P	=	6,		///<	1280X720	- for H.264, VP8
	VIDEO_QVGA	=	7		///<	320X240		- for H.264, VP8
}VIDEO_RESOLUTION;

/// The audio record file format
typedef enum
{
	FILEFORMAT_WAVE = 1,	///<	The record audio file is WAVE format. 
	FILEFORMAT_AMR,			///<	The record audio file is AMR format - all voice data is compressed by AMR codec. 
}AUDIO_FILE_FORMAT;

///The audio/Video record mode
typedef enum
{
	RECORD_NONE = 0,		///<	Not Record. 
	RECORD_RECV = 1,		///<	Only record the received data. 
	RECORD_SEND,			///<	Only record send data. 
	RECORD_BOTH				///<	The record audio file is WAVE format. 
}RECORD_MODE;



#define PORTSIP_LOCAL_MIX_ID -1		
#define PORTSIP_REMOTE_MIX_ID -2

///The audio stream callback mode
typedef enum
{
	AUDIOSTREAM_NONE = 0,
	AUDIOSTREAM_LOCAL_MIX,				///<	Callback the audio stream from microphone for all channels.
	AUDIOSTREAM_LOCAL_PER_CHANNEL,		///<  Callback the audio stream from microphone for one channel base on the session ID
	AUDIOSTREAM_REMOTE_MIX,				///<	Callback the received audio stream that mixed including all channels.
	AUDIOSTREAM_REMOTE_PER_CHANNEL,		///<  Callback the received audio stream for one channel base on the session ID.
}AUDIOSTREAM_CALLBACK_MODE;


///The video stream callback mode
typedef enum
{
	VIDEOSTREAM_NONE = 0,	///< Disable video stream callback
	VIDEOSTREAM_LOCAL,		///< Local video stream callback
	VIDEOSTREAM_REMOTE,		///< Remote video stream callback
	VIDEOSTREAM_BOTH,		///< Both of local and remote video stream callback
}VIDEOSTREAM_CALLBACK_MODE;


/// Log level
typedef enum
{
	PORTSIP_LOG_NONE = -1,
	PORTSIP_LOG_ERROR = 1,
	PORTSIP_LOG_WARNING = 2,
	PORTSIP_LOG_INFO = 3,
	PORTSIP_LOG_DEBUG = 4
}PORTSIP_LOG_LEVEL;



/// SRTP Policy
typedef enum
{
	SRTP_POLICY_NONE = 0,	///< No use SRTP, The SDK can receive the encrypted call(SRTP) and unencrypted call both, but can't place outgoing encrypted call. 
	SRTP_POLICY_FORCE,		///< All calls must use SRTP, The SDK just allows receive encrypted Call and place outgoing encrypted call only.
	SRTP_POLICY_PREFER		///< Top priority to use SRTP, The SDK allows receive encrypted and decrypted call, and allows place outgoing encrypted call and unencrypted call.
}SRTP_POLICY;


/// Transport for SIP signaling.
typedef enum
{
	TRANSPORT_UDP = 0,	///< UDP Transport
	TRANSPORT_TLS,		///< Tls Transport
	TRANSPORT_TCP,		///< TCP Transport
	TRANSPORT_PERS		///< PERS is the PortSIP private transport for anti the SIP blocking, it must using with the PERS Server http://www.portsip.com/pers.html.
}TRANSPORT_TYPE;

///The session refresh by UAC or UAS
typedef enum
{
	SESSION_REFERESH_UAC = 0,	///< The session refresh by UAC
	SESSION_REFERESH_UAS		///< The session refresh by UAS
}SESSION_REFRESH_MODE;

///send DTMF tone with two methods
typedef enum
{
	DTMF_RFC2833 = 0,	///<	send DTMF tone with RFC 2833, recommend.
	DTMF_INFO	 = 1	///<	send DTMF tone with SIP INFO.
}DTMF_METHOD;


// Audio and video callback function prototype, for Visual C++ only
typedef int  (* fnAudioRawCallback)(void * obj, 
									 long sessionId,
									 AUDIOSTREAM_CALLBACK_MODE type,
									 unsigned char * data, 
									 int dataLength,
									 int samplingFreqHz);  

typedef int (* fnVideoRawCallback)(void * obj, 
									long sessionId,
									VIDEOSTREAM_CALLBACK_MODE type, 
									int width, 
									int height, 
									unsigned char * data, 
									int dataLength);


// Callback functions for received and sending RTP packets, for Visual C++ only
typedef  int (* fnReceivedRTPPacket)(void *obj, long sessionId, bool isAudio, unsigned char * RTPPacket, int packetSize);
typedef  int (* fnSendingRTPPacket)(void *obj, long sessionId, bool isAudio, unsigned char * RTPPacket, int packetSize);

#ifndef __APPLE__
}
#endif
#endif
