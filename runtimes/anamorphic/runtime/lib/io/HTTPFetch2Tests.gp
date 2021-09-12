
// HTTPFetch2 Tests
// By default uses https://jsonplaceholder.typicode.com as test server.
// The localhost version of json-server can be launched with yarn --cwd=./scripts run start:json-server
//
// To run tests agains local server:  (run (new 'HTTPFetchTestSuite') 'http://localhost:3117')
//
defineClass HTTPFetchTestSuite baseURL
method run HTTPFetchTestSuite jsonServerURL {
	// setGlobal 'verboseHTTPFetch' true

	baseURL = jsonServerURL

	if (isNil baseURL) {
		baseURL = 'https://jsonplaceholder.typicode.com'
	}

	tm = (newTaskMaster)

	addTask tm (newTask (action 'testEncodeBodyWithDictionary' this ))
	addTask tm (newTask (action 'testEncodeBodyWithListsAndArrays' this ))
	addTask tm (newTask (action 'testEncodeBodyWithNestedListsAndArrays' this ))
	
	addTask tm (newTask (action 'testGET' this ))
	addTask tm (newTask (action 'testGETWithParams' this ))
	addTask tm (newTask (action 'testGETWithHeaders' this ))

	addTask tm (newTask (action 'testRestfulGET' this ))
	
	addTask tm (newTask (action 'testPOST' this ))

	stepAllTasksUntilDone tm
}

method testPOST HTTPFetchTestSuite {
	url = (join baseURL '/users')

	// POST /users just like regular HTML form (no nested dictionaries in body)
	body = (dictionary)
	atPut body 'name' 'Freddy Krueger'
	// $: curl --request POST --header "Content-Type: application/x-www-form-urlencoded" ${URL}/users --data 'name=Freddy%20Krueger'
	headers = nil // aka use the default content-type, just like html form 'application/x-www-form-urlencoded' 
	result = (httpPOST url body headers)

	assertNotEqual result '' 'request to test URL has failed'
	assert (isClass result 'BinaryData') true 'isClass result ''BinaryData'''
	newUser = (jsonParse (toString result))
	assert (at newUser 'name') (at body 'name') 'attribute name with value: '

	// POST to /users with json (nested dictionaries)
	body = (dictionary)
	atPut body 'name' 'Freddy Krueger'
	address = (dictionary)
	atPut address 'street' 'Elm Street'
	atPut body 'address' address

	headers = (list 'Content-Type:application/json')
	// $: curl --request POST --header "Content-Type:application/json" ${URL}/users --data '{"name": "Freddy Krueger", "address": {"street": "Elm Street"}}'
	result = (httpPOST url body headers)

	assertNotEqual result '' 'request to test URL has failed'
	assert (isClass result 'BinaryData') true 'isClass result ''BinaryData'''
	newUser = (jsonParse (toString result))
	assert (at newUser 'name') (at body 'name') 'attribute name with value: '
	assert (at (at newUser 'address') 'street') (at (at body 'address') 'street') 'attribute name with value: '
}


method testRestfulGET HTTPFetchTestSuite {
	url = (join baseURL '/posts') // localhost or https://jsonplaceholder.typicode.com/users
	posts = (restfulGET url)

	assertNotEqual result '' 'request to test URL has failed'

	assert (isClass posts 'List') true '(isClass users ''List'')'
	assert (count posts) 100

	assert (at (at posts 1) 'id') 1 'first user has id==1'
	assert (at (last posts ) 'id') 100 'last user has id==100'
}

method testGETWithParams HTTPFetchTestSuite {
	url = (join baseURL '/posts')

	// GET /posts?q=voluptatem%20laborum
	// $: curl --request GET  ${URL}/posts\?q=voluptatem%20laborum
	params = (dictionary)
	atPut params 'q' 'voluptatem laborum'
	result = (httpGET url params)
	assertNotEqual result '' 'request to test URL has failed'
	assert (isClass result 'BinaryData') true 'isClass result ''BinaryData'''
	assert (count (jsonParse (toString result))) 1 '''/posts?q=voluptatem%20laborum'' size'

	// GET /posts?id=1&id=2
	// $: curl --request GET  ${URL}/posts\?id=1\&id=2
	params = (list (list 'id' 1) (list 'id' 2))
	result = (httpGET url params)
	assert (count (jsonParse (toString result))) 2 'a list of ids: ''/posts?id=1&id=2'' size'

	// GET /posts?id=1&id=2
	params = (array (list 'id' 1) (array 'id' 2))
	result = (httpGET url params)
	assert (count (jsonParse (toString result))) 2 'an array of ids: ''/posts?id=1&id=2'' size'
}

method testGET HTTPFetchTestSuite {
	url = (join baseURL '/posts') // localhost or https://jsonplaceholder.typicode.com/users
	result = (httpGET url)

	assertNotEqual result '' 'request to test URL has failed'

	assert (isClass result 'BinaryData') true 'isClass result ''BinaryData'''
	posts = (jsonParse (toString result))

	assert (isClass posts 'List') true '(isClass users ''List'')'
	assert (count posts) 100

	assert (at (at posts 1) 'id') 1 'first user has id==1'
	assert (at (last posts ) 'id') 100 'last user has id==100'
}
// Note headers test requires a special endpoint available only in the local server version
// For details look at json-server.js
method testGETWithHeaders HTTPFetchTestSuite {
	isJsonServerOnLocalhost = (not (isNil (findSubstring 'localhost' baseURL)))

	if (not isJsonServerOnLocalhost) {
		print 'headers test method requires a json-server on localhost, SKIPPING' 
		return
	}
	url = (join baseURL '/headers')

	result = (httpGET url nil nil 200)
	assertNotEqual result '' 'request to test URL has failed'
	assert (isClass result 'BinaryData') true 'isClass result ''BinaryData'''
	result = (jsonParse (toString result))
	assert (at result 'error') true 'no headers given, error expected'

	notAllHeaders = (list 
	'Authorization: Basic YWxhZGRpbjpvcGVuc2VzYW1l'
	)
	result = (httpGET url nil notAllHeaders)
	assert (at (jsonParse (toString result)) 'error') true 'not ALL required headers were given, error='
	
	expectedHeaders = (list 
	'Authorization: Basic YWxhZGRpbjpvcGVuc2VzYW1l'
    'x-gp-header: HTTPFetchTestSuite'
	)

	result = (httpGET  url nil expectedHeaders)
	assert (at (jsonParse (toString result)) 'error') false 'all headers where given error='
}
method testEncodeBodyWithListsAndArrays HTTPFetchTestSuite {
	valueIsConvertedToString = (list 'id' 1 'id' '2')
	assert (encodeBody valueIsConvertedToString false) 'id=1&id=2' '(list ''id'' 1 ''id'' ''2'')'

	toShortList = (list)
	assert (encodeBody toShortList false) nil '(list)'
	
	parameterWithoutValue = (list 'id')
	assert (encodeBody parameterWithoutValue false) nil

	evenNumberOfElements = (list 'id' 1 'a' 2 'b' 3 4)
	assert (encodeBody evenNumberOfElements false) 'id=1&a=2&b=3'
	

	bodyAsArray = (array 'id' 1 'id' 2)
	assert (encodeBody bodyAsArray false) 'id=1&id=2' 'array id=1&id=2'
}

method testEncodeBodyWithNestedListsAndArrays HTTPFetchTestSuite {
	valueIsConvertedToString = (list (list 'id' 1) (list 'id' '2'))
	assert (encodeBody valueIsConvertedToString false) 'id=1&id=2' 'list id=1&id=2'

	toShortList = (list)
	assert (encodeBody toShortList false) nil 'toShortList'
	
	parameterWithoutValue = (list (list 'id'))
	assert (encodeBody parameterWithoutValue false) nil 'parameterWithoutValue'

	nestedListsAreFlattened = (list (list 'id' 1 2 3 4) (array 'f o' nil 'b o' nil))
	// nestedListsAreFlattened flattened looks like: (list ['id' 1] [2 3] [4 'f o'] [nil 'b o'] nil) 
	assert (encodeBody nestedListsAreFlattened false) 'id=1&2=3&4=f%20o&nil=b%20o' 'nestedListsAreFlattened'
	
	toString = (list (list 1 2 3 4 5))
	assert (encodeBody toString false) '1=2&3=4' 'toString'

	bodyAsList = (list (list 'id' 1) (list 'id' 2))
	assert (encodeBody bodyAsList false) 'id=1&id=2' 'bodyAsList'

	bodyAsArray = (array (list 'id' 1) (list 'id' 2))
	assert (encodeBody bodyAsArray false) 'id=1&id=2' 'bodyAsArray'

}
method testEncodeBodyWithDictionary HTTPFetchTestSuite {
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
