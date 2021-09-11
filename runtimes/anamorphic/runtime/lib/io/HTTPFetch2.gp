
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
to httpFetch url method headers postBody timeout {
	if (isNil method) { method = 'GET' }
	if (isNil url) { 
		error 'URL is empty'
	 }
	if (not (isNil headers)) { headers = (toArray headers)}
	if (not (isNil postBody)) { postBody = (toString postBody)}

	if (not (isNil timeout)) { timeout = (toInteger timeout)}

	if (isNil timeout) { timeout = 2000 }

	if ((global 'verboseHTTPFetch') == true) {
		print '🤙 ' method '
	url:' url '
	headers:' headers '
	body:' body '
	timeout:' timeout
	}

	requestID = (startRequest url method headers postBody timeout)
	start = (msecsSinceStart)
	while (((msecsSinceStart) - start) < timeout) {
		result = (fetchRequestResult requestID)
		if (false == result) { return '' } // request failed
		if (notNil result) { return result } // request completed
		waitMSecs 20
	}

    // The request took to long to finish, before return give a chance to cleanup prims internal data
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
