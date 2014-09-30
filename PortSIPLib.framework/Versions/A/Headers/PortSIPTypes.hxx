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


// Audio codec 
typedef enum
{
	AUDIOCODEC_NONE		= -1,	
	AUDIOCODEC_G729		= 18,	//8KHZ
	AUDIOCODEC_PCMA		= 8,	//8KHZ
	AUDIOCODEC_PCMU		= 0,	//8KHZ
	AUDIOCODEC_GSM		= 3,	//8KHZ
	AUDIOCODEC_G722		= 9,	//16KHZ
	AUDIOCODEC_ILBC		= 97,	//8KHZ
	AUDIOCODEC_AMR		= 98,	//8KHZ
	AUDIOCODEC_AMRWB	= 99,	//16KHZ
	AUDIOCODEC_SPEEX	= 100,	//8KHZ
	AUDIOCODEC_SPEEXWB	= 102,	//16KHZ
	AUDIOCODEC_ISACWB	= 103,	//16KHZ
	AUDIOCODEC_ISACSWB	= 104,	//32KHZ
	AUDIOCODEC_G7221	= 121,	//16KHZ
	AUDIOCODEC_OPUS		= 105,	//48KHZ,32kbps
	AUDIOCODEC_DTMF		= 101
}AUDIOCODEC_TYPE;



// Video codec
typedef enum
{
	VIDEO_CODE_NONE				= -1,
	VIDEO_CODEC_I420			= 113,
	VIDEO_CODEC_H263			= 34,
	VIDEO_CODEC_H263_1998		= 115,
	VIDEO_CODEC_H264			= 125,
	VIDEO_CODEC_VP8				= 120
}VIDEOCODEC_TYPE;



typedef enum
{
	VIDEO_NONE	=	0,	
	VIDEO_QCIF	=	1,		//	176X144		- for H.263, H.263-1998, H.264
	VIDEO_CIF	=	2,		//	352X288		- for H.263, H.263-1998, H.264
	VIDEO_VGA	=	3,		//	640X480		- for H.264 only
	VIDEO_SVGA	=	4,		//	800X600		- for H.264 only
	VIDEO_XVGA	=	5,		//	1024X768	- for H.264 only
	VIDEO_720P	=	6,		//	1280X720	- for H.264 only
	VIDEO_QVGA	=	7		//	320X240		- for H.264 only
}VIDEO_RESOLUTION;


typedef enum
{
	FILEFORMAT_WAVE = 1,
	FILEFORMAT_AMR,
}AUDIO_FILE_FORMAT;

typedef enum
{
	RECORD_NONE = 0,
	RECORD_RECV = 1,
	RECORD_SEND,
	RECORD_BOTH
}RECORD_MODE;


// For the audio callback
#define PORTSIP_LOCAL_MIX_ID -1
#define PORTSIP_REMOTE_MIX_ID -2


typedef enum
{
	AUDIOSTREAM_NONE = 0,
	AUDIOSTREAM_LOCAL_MIX,				//	Callback the audio stream from microphone for all channels.
	AUDIOSTREAM_LOCAL_PER_CHANNEL,		//  Callback the audio stream from microphone for one channel base on the session ID
	AUDIOSTREAM_REMOTE_MIX,				//	Callback the received audio stream that mixed including all channels.
	AUDIOSTREAM_REMOTE_PER_CHANNEL,		//  Callback the received audio stream for one channel base on the session ID.
}AUDIOSTREAM_CALLBACK_MODE;



typedef enum
{
	VIDEOSTREAM_NONE = 0,	// Disable video stream callback
	VIDEOSTREAM_LOCAL,		// Local video stream callback
	VIDEOSTREAM_REMOTE,		// Remote video stream callback
	VIDEOSTREAM_BOTH,		// Both of local and remote video stream callback
}VIDEOSTREAM_CALLBACK_MODE;



typedef enum
{
	PRESENCE_P2P,
	PRESENCE_AGENT
}PRESENCE_MODE;


 // Log level
typedef enum
{
	PORTSIP_LOG_NONE = -1,
	PORTSIP_LOG_ERROR = 1,
	PORTSIP_LOG_WARNING = 2,
	PORTSIP_LOG_INFO = 3,
	PORTSIP_LOG_DEBUG = 4
}PORTSIP_LOG_LEVEL;



// SRTP Policy
typedef enum
{
	SRTP_POLICY_NONE = 0,	// No use SRTP
	SRTP_POLICY_FORCE,		// All calls must use SRTP
	SRTP_POLICY_PREFER		// Top priority to use SRTP
}SRTP_POLICY;



// Transport
typedef enum
{
	TRANSPORT_UDP = 0,
	TRANSPORT_TLS,
	TRANSPORT_TCP,
	TRANSPORT_PERS
}TRANSPORT_TYPE;


typedef enum
{
	SESSION_REFERESH_UAC = 0,
	SESSION_REFERESH_UAS
}SESSION_REFRESH_MODE;


typedef enum
{
	DTMF_RFC2833 = 0,
	DTMF_INFO	 = 1
}DTMF_METHOD;


// Audio and video callback function prototype
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


// Callback functions for received and sending RTP packets
typedef  int (* fnReceivedRTPPacket)(void *obj, long sessionId, bool isAudio, unsigned char * RTPPacket, int packetSize);
typedef  int (* fnSendingRTPPacket)(void *obj, long sessionId, bool isAudio, unsigned char * RTPPacket, int packetSize);

#ifndef __APPLE__
}
#endif
#endif
