
// HTTPFetch2

to restfulGET url parameters headers timeout {
	if (isNil headers) { headers = (list)}

	(add headers 'Content-Type: application/json')
	
	result = (httpGET url parameters headers timeout)
	if (isClass result 'BinaryData') {
		return (jsonParse (toString result))
	}

	return result
}

to httpGET url parameters headers timeout {
	
	fetchURL = url
	queryString = (encodeBody parameters false)

	if (not (isNil queryString)) {
		fetchURL = (joinStrings (list url '?' queryString))
	}

	return (httpFetch fetchURL 'GET' headers nil timeout)
}

to httpPOST url body headers timeout {
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
	if (isEmpty headers) { headers = nil}
	if (not (isNil headers)) { headers = (toArray headers)}

	if (isEmpty postBody) { postBody = nil}
	if (not (isNil postBody)) { postBody = (toString postBody)}

	if (<= timeout 0) { timeout = nil}

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
// When called with list or array, for non json encoding, body is first flattened and then splitted into name, value pairs. 
to encodeBody body asJSON {
	if (or (isNil body) (isEmpty body)){
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
		nameValuePair = (list)
		for element (toList (flattened body)) {	
			item = (percentEncode (toString element))
			len = (count nameValuePair)
			if (len == 1) {
				(add nameValuePair '=')
				(add nameValuePair item)

				(add encoded (joinStrings nameValuePair))
				nameValuePair = (list)
			} (len == 0) {
				(add nameValuePair item)
			}
  		}
	}

	if (isEmpty encoded) {
		return nil
	}

	return (joinStrings encoded '&') 
}
