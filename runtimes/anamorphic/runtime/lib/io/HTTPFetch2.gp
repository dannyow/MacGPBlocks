
// HTTPFetch2

to restfulGET url headers body timeout {
	if (isNil headers) { headers = (list)}

	(add headers 'Content-Type: application/json')
	
	result = (httpFetch url 'GET' headers (encodeBody body ) timeout)
	if (isClass result 'BinaryData') {
		return (jsonParse (toString result))
	}

	return result
}

to httpGET url headers params timeout {
	
	fetchURL = url
	queryString = (encodeBody params false)

	if (not (isNil queryString)) {
		fetchURL = (joinStrings (list url '?' queryString))
	}

	return (httpFetch fetchURL 'GET' headers nil timeout)
}

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

// Converts 'body' into a string encoded and ready for use in a request.
//
// Returns string or nil, throws error on wront type of input.
// When called with a dictionary, only entries that are strings value are used.
// When called with list/array, expects at least 2 values per parameter, name is string, value is converted to string.
to encodeBody body asJSON {
	if (isNil body){
		return nil
	}  

	if (not (or (isClass body 'Dictionary') (isClass body 'List') (isClass body 'Array'))) {
		error 'Data to encode must be a dictionary/list/array or nil'
  	}
	
	if (true == asJSON) {
		return (jsonStringify body)
	}

	encoded = (list)

	if (isClass body 'Dictionary') {
		values = (values body)
		keys = (keys body)
		for i (count keys) {
			v = (at values i)
			if (isClass v 'String'){
				nameValuePair = (list (at keys i) '=' (percentEncode v))
				(add encoded (joinStrings nameValuePair))
			}
		}
	} else {
		for param (toList body) {
			if (and ( > (count param) 1) (isClass (at param 1) 'String') ) {
				v = (toString (at param 2))
				nameValuePair = (list (at param 1) '=' (percentEncode v))
				(add encoded (joinStrings nameValuePair))
			}
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