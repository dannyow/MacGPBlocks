
// HTTPFetch2
//https://github.com/typicode/json-server#plural-routes

defineClass HTTPFetchTestSuite baseURL
method run HTTPFetchTestSuite {
	// setGlobal 'URL' 'http://localhost:3117'
	baseURL = 'http://localhost:3117'
	// baseURL = 'https://jsonplaceholder.typicode.com'

	tm = (newTaskMaster)

	addTask tm (newTask (action 'testEncodeBody' this ))
	addTask tm (newTask (action 'testGet' this ))
	addTask tm (newTask (action 'testGetWithHeaders' this ))

	stepAllTasksUntilDone tm
}

method testGet HTTPFetchTestSuite {
	url = (join baseURL '/users') // localhost or https://jsonplaceholder.typicode.com/users
	result = (httpGET url)

	assertNotEqual result '' 'request to test URL has failed'

	assert (isClass result 'BinaryData') true 'isClass result ''BinaryData'''
	users = (jsonParse (toString result))

	assert (isClass users 'List') true '(isClass users ''List'')'
	assert (count users) 10

	assert (at (at users 1) 'id') 1 'first user has id==1'
	assert (at (last users ) 'id') 10 'last user has id==10'
}

// Note headers test requires special endpoint available only in local server
method testGetWithHeaders HTTPFetchTestSuite {

	headers = (list 
	'Authorization: Basic YWxhZGRpbjpvcGVuc2VzYW1l'
	'Pragma:no-cache'
	'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36'
	)

	url = (join baseURL '/users')
	result = (httpGET  url headers)

	
	assert (isClass result 'BinaryData') true
	users = (jsonParse (toString result))

	assert (isClass users 'List') true '(isClass users ''List'')'
	assert (count users) 10

	assert (at (at users 1) 'id') 1 'first user has id==1'
	assert (at (last users ) 'id') 10 'last user has id==10'
}

method testEncodeBody HTTPFetchTestSuite {
	// returns nil if no body was given
	assert (encodeBody nil true), nil
	assert (encodeBody nil false), nil

	// returns JSON string if the 2nd param is true
	body = (dictionary)
	atPut body 'name' 'Freddy Krueger 🤠👨‍👩‍👧‍👦'
	address = (dictionary)
	atPut address 'street' 'Elm Street'
	atPut address 'city' 'Springwood'
	atPut address 'suite' '1428C'
	atPut body 'address' address
	
	jsonString = (encodeBody body true)
	bodyFromJSON = (jsonParse jsonString)

	assert (at bodyFromJSON 'name') (at body 'name')
	assert (at (at bodyFromJSON 'address') 'street')  (at (at body 'address') 'street')
	assert (at (at bodyFromJSON 'address') 'city')  (at (at body 'address') 'city')
	assert (at (at bodyFromJSON 'address') 'suite')  (at (at body 'address') 'suite')

	// if body contains only nested object, the result is nil
	outer = (dictionary)
	inner1 = (array 1 2 3)
	inner2 = (dictionary)
	atPut inner2 'key' 1
	atPut outer 'array' inner1
	atPut outer 'dictionary' inner2

	assert (encodeBody outer false) nil

	// returns query encoded string if the 2nd param is false
	queryString = (encodeBody body false)
	assert queryString 'name=Freddy%20Krueger%20%F0%9F%A4%A0%F0%9F%91%A8%E2%80%8D%F0%9F%91%A9%E2%80%8D%F0%9F%91%A7%E2%80%8D%F0%9F%91%A6' 

	queryString = (encodeBody address false)
	assert queryString 'city=Springwood&street=Elm%20Street&suite=1428C' 
}


to runHttpFetchTests {
	// $: export URL=http://localhost:3117'
	setGlobal 'URL' 'http://localhost:3117'

	// assert false true 'message'
	// assertNotEqual true true 'message'

	// test_httpPOSTBody
	// test_httpGETBody
	test_httpGETHeaders
	test_encodeBody

// tm = (newTaskMaster)
//   addTask tm (newTask (action 'runTask' this 'A' 24))

//   stepAllTasksUntilDone tm
	
}

to test_httpPOSTBody {

	url = (join (global 'URL') '/users')

	// POST /users just like regular HTML form (no nested dictionaries in body)
	body = (dictionary)
	atPut body 'name' 'Freddy Krueger'
	// $: curl --request POST --header "Content-Type: application/x-www-form-urlencoded" ${URL}/users --data 'name=Freddy%20Krueger'
	headers = nil // aka use the default content-type, just like html form 'application/x-www-form-urlencoded' 
	httpPOST url headers body

	// $: curl --request POST --header "Content-Type: application/x-www-form-urlencoded" --header "X-Testing: value" ${URL}/users --data 'name=Freddy%20Krueger'
	headers = (list 'X-Testing: value')
	httpPOST url headers body


	// use json
	body = (dictionary)
	atPut body 'name' 'Freddy Krueger'
	address = (dictionary)
	atPut address 'street' 'Elm Street'
	atPut body 'address' address

	headers = (list 'Content-Type:application/json')
	// $: curl --request POST --header "Content-Type:application/json" ${URL}/users --data '{"name": "Freddy Krueger", "address": {"street": "Elm Street"}}'
	httpPOST url headers body
}


to test_httpGETBody {
	url = (join (global 'URL') '/posts')

	// GET /post?q=voluptatem%20laborum
	body = (dictionary)
	atPut body 'q' 'voluptatem laborum'
	httpGET url nil body

	// GET /posts?id=1&id=2
	body = (list (list 'id' 1) (list 'id' 2))
	httpGET url nil body

	// GET /posts?id=1&id=2
	body = (array (list 'id' 1) (array 'id' 2))
	httpGET url nil body
}


// Headers is expected to be a list of strings or nil.
// Each string will be used as a request header entry as-is, as such string should contain both key and value.
// Example: 'Pragma: no-cache' or 'Authorization: Bearer mF_9.B5f-4.1JqM'
to test_httpGETHeaders {
	headers = (list 
	'Authorization: Basic YWxhZGRpbjpvcGVuc2VzYW1l'
	'Pragma:no-cache'
	'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36'
	)

	url = (join (global 'URL') '/users')
	httpGET  url headers
}

to test_encodeBody {
	// returns nil if no body was given
	assert (encodeBody nil true), nil
	assert (encodeBody nil false), nil

	// returns JSON string if the 2nd param is true
	body = (dictionary)
	atPut body 'name' 'Freddy Krueger 🤠👨‍👩‍👧‍👦'
	address = (dictionary)
	atPut address 'street' 'Elm Street'
	atPut address 'city' 'Springwood'
	atPut address 'suite' '1428C'
	atPut body 'address' address
	
	jsonString = (encodeBody body true)
	bodyFromJSON = (jsonParse jsonString)

	assert (at bodyFromJSON 'name') (at body 'name')
	assert (at (at bodyFromJSON 'address') 'street')  (at (at body 'address') 'street')
	assert (at (at bodyFromJSON 'address') 'city')  (at (at body 'address') 'city')
	assert (at (at bodyFromJSON 'address') 'suite')  (at (at body 'address') 'suite')

	// if body contains only nested object, the result is nil
	outer = (dictionary)
	inner1 = (array 1 2 3)
	inner2 = (dictionary)
	atPut inner2 'key' 1
	atPut outer 'array' inner1
	atPut outer 'dictionary' inner2

	assert (encodeBody outer false) nil

	// returns query encoded string if the 2nd param is false
	queryString = (encodeBody body false)
	assert queryString 'name=Freddy%20Krueger%20%F0%9F%A4%A0%F0%9F%91%A8%E2%80%8D%F0%9F%91%A9%E2%80%8D%F0%9F%91%A7%E2%80%8D%F0%9F%91%A6' 

	queryString = (encodeBody address false)
	assert queryString 'city=Springwood&street=Elm%20Street&suite=1428C' 
}