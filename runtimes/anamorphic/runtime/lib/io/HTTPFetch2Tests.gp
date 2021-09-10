
// HTTPFetch2
//https://github.com/typicode/json-server#plural-routes

defineClass HTTPFetchTestSuite baseURL
method run HTTPFetchTestSuite {
	setGlobal 'verboseHTTPFetch' true
	baseURL = 'http://localhost:3117'
	// baseURL = 'https://jsonplaceholder.typicode.com'

	tm = (newTaskMaster)

	addTask tm (newTask (action 'testEncodeBody' this ))
	addTask tm (newTask (action 'testGet' this ))
	addTask tm (newTask (action 'testGetWithHeaders' this ))
	addTask tm (newTask (action 'testGETBody' this ))
	addTask tm (newTask (action 'testPOSTBody' this ))

	stepAllTasksUntilDone tm
}

method testPOSTBody HTTPFetchTestSuite {
	url = (join baseURL '/users')

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
method testGETBody HTTPFetchTestSuite {
	url = (join baseURL '/posts')

	// GET /posts?q=voluptatem%20laborum
	// $: curl --request GET  ${URL}/posts\?q=voluptatem%20laborum
	body = (dictionary)
	atPut body 'q' 'voluptatem laborum'
	result = (httpGET url nil body)
	assertNotEqual result '' 'request to test URL has failed'
	assert (isClass result 'BinaryData') true 'isClass result ''BinaryData'''
	assert (count (jsonParse (toString result))) 1 '''/posts?q=voluptatem%20laborum'' size'

	// GET /posts?id=1&id=2
	// $: curl --request GET  ${URL}/posts\?id=1\&id=2
	body = (list (list 'id' 1) (list 'id' 2))
	result = (httpGET url nil body)
	assert (count (jsonParse (toString result))) 2 'a list of ids: ''/posts?id=1&id=2'' size'

	// GET /posts?id=1&id=2
	body = (array (list 'id' 1) (array 'id' 2))
	result = (httpGET url nil body)
	assert (count (jsonParse (toString result))) 2 'an array of ids: ''/posts?id=1&id=2'' size'
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

// Note headers test requires a special endpoint available only in the local server version
method testGetWithHeaders HTTPFetchTestSuite {

	isJsonServerOnLocalhost = (not (isNil (findSubstring 'localhost' baseURL)))
	assert isJsonServerOnLocalhost true '(testGetWithHeaders) test method requires localhost server' 

	if (not isJsonServerOnLocalhost) {
		return
	}

	headers = (list 
	'Authorization: Basic YWxhZGRpbjpvcGVuc2VzYW1l'
	'User-Agent: HTTPFetchTestSuite'
	)

	url = (join baseURL '/headers')
	result = (httpGET  url headers)

	// TODO
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
