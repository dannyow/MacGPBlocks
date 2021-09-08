
// HTTPFetch2


// The timeout here means _also_ how long we want to wait to get the received data 
// Fetching large file over a slow network plus and a short timeout => no chance for success
to restGet url headers timeout {
    
	if (isNil timeout) { timeout = 1000 }
	// if (and (beginsWith (browserURL) 'https:') (beginsWith url 'http:')) { // switch to 'https'
	// 	url = (join 'https://' (substring url 8))
	// }

    // TODO: pack headers into list of strings to ease out using headers with libcurl
    // TODO: add option(s) ? to pass extra data (?) like start page numer etc
    // TODO: add isomorphic :) startFetch to support both browser and native apps
	requestID = (startRequest url )
	start = (msecsSinceStart)
	while (((msecsSinceStart) - start) < timeout) {
		result = (fetchRequestResult requestID)
		if (false == result) { return '' } // request failed
		if (notNil result) { return result } // request completed
		waitMSecs 20
	}

    // The time is off, let's give a chance to cleanup prims internal data, since this request is done
    (cancelRequest requestID)
    // ???: what should be returned in there is a timeout?
    //return '' // for now to match request failed result from above...
    return nil
}

to restfulPOST url headers body timeout {
	if (isNil headers) { headers = (list)}

	(add header 'Content-Type: application/json')
	// convert body to json
	//cache-control: no-cache
	//accept: */*
	bodyJSONString = '{}'

	httpFetch 'POST' url (headers toArray) bodyJSONString timeout
}

to httpPOST url headers body timeout {
	if (isNil headers) { headers = (list)}

	// convert body to query parameters
	(add headers 'Content-Type: application/x-www-form-urlencoded')
}
to httpGET url headers body timeout {
	// convert body to query parameters
}

to httpFetch method url headersArray body timeout {
	if (isNil method) { method = 'GET' }
	if (isNil url) { return nil }
	if (isNil headersArray) { headersArray = (array)}
	if (isNil body) { body = (dictionary) }
	if (isNil timeout) { timeout = 2000 }


}