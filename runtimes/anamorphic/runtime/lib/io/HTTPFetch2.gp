
// HTTPFetch2

to httpPOST url headers body timeout {
	if (or (isNil headers) (isEmpty headers)) { headers = (list)}

	encodeAsJSON = false
	useDefaultContentType = (isEmpty headers)

	if (not (isEmpty headers)) {
  		hasContentType = (function item {
		  return (beginsWith (toLowerCase item) 'content-type:')
		})
		contentTypeHeader = (detect hasContentType headers)
		if (isNil contentTypeHeader) {
			useDefaultContentType = true
			encodeAsJSON = false
		} else {
			useDefaultContentType = false
			encodeAsJSON = (not (isNil (findSubstring 'application/json' contentTypeHeader)))
		}
	}

	if (true == useDefaultContentType) {
		(add headers 'Content-Type: application/x-www-form-urlencoded')
	}

	return (httpFetch url 'POST' headers (encodeBody body encodeAsJSON) timeout)
}

to httpGET url headers body timeout {
	return (httpFetch url 'GET' headers (encodeBody body ) timeout)
}

// Headers is expected to be a list of strings or nil.
// Each string will be used as a request header entry as-is, as such string should contain both key and value.
// Example: 'Pragma: no-cache' or 'Authorization: Bearer mF_9.B5f-4.1JqM'
to httpFetch url method headers body timeout {
	if (isNil method) { method = 'GET' }
	if (isNil url) { 
		error 'URL is empty'
	 }
	if (isNil headers) { headers = (list)}
	//if (isNil body) { body = (dictionary) }
	if (isNil timeout) { timeout = 2000 }

	if ((global 'verboseHTTPFetch') == true) {
		print '🤙 ' method '
	url:' url '
	headers:' headers '
	body:' body
	}

//https://stackoverflow.com/questions/11281117/x-www-form-urlencoded-vs-json-http-post

	requestID = (startRequest url method (toArray headers) (toString body) timeout)
	start = (msecsSinceStart)
	while (((msecsSinceStart) - start) < timeout) {
		result = (fetchRequestResult requestID)
		if (false == result) { return '' } // request failed
		if (notNil result) { return result } // request completed
		waitMSecs 20
	}

    // Request's time is off, give a chance to cleanup prims internal data
    (cancelRequest requestID)

    // ???: what should be returned in there is a timeout?
    //return '' // for now to match request failed result from above...
    return nil
}

// Converts input dictionary into string encoded for use in request.
// Returns string or nil (on nil imput or empty/not convertable dictionary)
// When converting to a query string, only entries from body that value is string will be used.
to encodeBody body asJSON {
	if (not (or (isNil body) (isClass body 'Dictionary'))) {
		error 'Data to encode must be a dictionary or nil'
  	}
	if (isNil body){
		return nil
	}  

	if (true == asJSON) {
		return (jsonStringify body)
	}
	
	encoded = (list)
	values = (values body)
	keys = (keys body)
	for i (count keys) {
		v = (at values i)
		if (isClass v 'String'){
			nameValuePair = (list (at keys i) '=' (percentEncode v))
			(add encoded (joinStrings nameValuePair))
		}
	}

	if (isEmpty encoded) {
		return nil
	}

	return (joinStrings encoded '&') 
}

// // HTTPFetch2



// // The timeout here means _also_ how long we want to wait to get the received data 
// // Fetching large file over a slow network plus and a short timeout => no chance for success
// to restGet url headers timeout {
    
// 	if (isNil timeout) { timeout = 1000 }
// 	// if (and (beginsWith (browserURL) 'https:') (beginsWith url 'http:')) { // switch to 'https'
// 	// 	url = (join 'https://' (substring url 8))
// 	// }

//     // TODO: pack headers into list of strings to ease out using headers with libcurl
//     // TODO: add option(s) ? to pass extra data (?) like start page numer etc
//     // TODO: add isomorphic :) startFetch to support both browser and native apps
// 	requestID = (startRequest url )
// 	start = (msecsSinceStart)
// 	while (((msecsSinceStart) - start) < timeout) {
// 		result = (fetchRequestResult requestID)
// 		if (false == result) { return '' } // request failed
// 		if (notNil result) { return result } // request completed
// 		waitMSecs 20
// 	}

//     // The time is off, let's give a chance to cleanup prims internal data, since this request is done
//     (cancelRequest requestID)
//     // ???: what should be returned in there is a timeout?
//     //return '' // for now to match request failed result from above...
//     return nil
// }

// to restfulPOST url headers body timeout {
// 	if (isNil headers) { headers = (list)}

// 	(add header 'Content-Type: application/json')
// 	// convert body to json
// 	//cache-control: no-cache
// 	//accept: */*
// 	bodyJSONString = '{}'

// 	httpFetch 'POST' url (headers toArray) bodyJSONString timeout
// }

// // The timeout here means _also_ how long we want to wait to get the received data 
// // Fetching large file over a slow network plus and a short timeout => no chance for success
// to restGet url headers timeout {
    
// 	if (isNil timeout) { timeout = 1000 }
// 	// if (and (beginsWith (browserURL) 'https:') (beginsWith url 'http:')) { // switch to 'https'
// 	// 	url = (join 'https://' (substring url 8))
// 	// }

//     // TODO: pack headers into list of strings to ease out using headers with libcurl
//     // TODO: add option(s) ? to pass extra data (?) like start page numer etc
//     // TODO: add isomorphic :) startFetch to support both browser and native apps
// 	requestID = (startRequest url )
// 	start = (msecsSinceStart)
// 	while (((msecsSinceStart) - start) < timeout) {
// 		result = (fetchRequestResult requestID)
// 		if (false == result) { return '' } // request failed
// 		if (notNil result) { return result } // request completed
// 		waitMSecs 20
// 	}

//     // The time is off, let's give a chance to cleanup prims internal data, since this request is done
//     (cancelRequest requestID)
//     // ???: what should be returned in there is a timeout?
//     //return '' // for now to match request failed result from above...
//     return nil
// }

// to httpGetFromURL url headers timeout {
// 	return (httpFetch 'GET' url headers timeout)
// }

// to restGet url headers data timeout {

// }

// to restPost url headers timeout {

// }

// to restPut url headers timeout {

// }

// to restDelete url headers timeout {

// }


// // The workhorse of all calls, kind of private.
// // The timeout here means _also_ how long we want to wait to get the received data.
// // Fetching a large payload via a slow network with a short timeout will fail, simply because
// // downloading the payload takes longer than the timeout (without a connection timeout per se).
// // Returns:
// // * BinaryData on success
// // * '' on failure
// // * nil on timeout
// to httpFetch method url headers body timeout {
// 	if (isNil method) { method = 'GET' }
// 	if (isNil url) { return nil }
// 	if (isNil headers) { headers = (array)}
// 	if (isNil timeout) { timeout = 5000 }

// 	requestID = (startRequest method url headersArray timeout)
// 	start = (msecsSinceStart)
// 	while (((msecsSinceStart) - start) < timeout) {
// 		result = (fetchRequestResult requestID)
// 		if (false == result) { return '' } // request failed
// 		if (notNil result) { return result } // request completed
// 		waitMSecs 20
// 	}

//     // The time is off, give a chance to cleanup prims internal data, since this request won't be used
//     (cancelRequest requestID)

//     // ???: what should be returned in there is a timeout?
//     //return '' // for now to match request failed result from above...
//     return nil

// }