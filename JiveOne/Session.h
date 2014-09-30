/*
    PortSIP 11.2
    Copyright (C) 2014 PortSIP Solutions, Inc.
   
    support@portsip.com

    Visit us at http://www.portsip.com
*/


#ifndef PORTSIP_SESSION_hxx
#define PORTSIP_SESSION_hxx

#define LINE_BASE 0
#define MAX_LINES 8

class Session
{
public:
	Session()
		:mSessionId(INVALID_SESSION_ID)
		,mHoldSate(false)
		,mSessionState(false)
		,mConferenceState(false)
		,mRecvCallState(false)
		,mOriginCallSessionId(INVALID_SESSION_ID)
		,mIsReferCall(false)
		,mExistEarlyMedia(false)
        ,mVideoState(false)
	{

	}
	virtual ~Session(){}

public:

	void setExistEarlyMedia(bool state)
	{
		mExistEarlyMedia = state;
	}

	bool getExistEarlyMedia()
	{
		return mExistEarlyMedia;
	}

	void setSessionId(long sessionId)
	{
		mSessionId = sessionId;
	}


	long getSessionId()
	{
		return mSessionId;
	}

	void setHoldState(bool state)
	{
		mHoldSate = state;
	}


	bool getHoldState()
	{
		return mHoldSate;
	}

	void setSessionState(bool state)
	{
		mSessionState = state;
	}



	bool getSessionState()
	{
		return mSessionState;
	}


	void setRecvCallState(bool state)
	{
		mRecvCallState = state;
	}

	bool getRecvCallState()
	{
		return mRecvCallState;
	}

	void reset()
	{
		mSessionId = INVALID_SESSION_ID;
		mHoldSate = false;
		mSessionState = false;
		mConferenceState = false;
		mRecvCallState = false;
		mIsReferCall = false;
		mOriginCallSessionId = INVALID_SESSION_ID;
		mExistEarlyMedia = false;
        mVideoState = false;
	}

	bool isReferCall() { return mIsReferCall; }
	long getOriginCallSessionId() { return mOriginCallSessionId; }
	void setReferCall(bool referCall, long originCallSessionId)
	{
		mIsReferCall = referCall;
		mOriginCallSessionId = originCallSessionId;
	}
	void setVideoState(bool state)
	{
		mVideoState = state;
	}
    
    
    
	bool getVideoState()
	{
		return mVideoState;
	}

protected:


private:

	long mSessionId;
	bool mHoldSate;
	bool mSessionState;
	bool mConferenceState;
	bool mRecvCallState;
	bool mIsReferCall;
	long mOriginCallSessionId;
	bool mExistEarlyMedia;
    bool mVideoState;
};




#endif

