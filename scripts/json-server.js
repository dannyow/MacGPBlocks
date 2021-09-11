
require('dotenv/config');

// https://github.com/typicode/json-server
const jsonServer = require('json-server');
// Copy of data from from http://jsonplaceholder.typicode.com/db
const db = require('./json-server-db.json');

const server = jsonServer.create();
const router = jsonServer.router(db);
const middlewares = jsonServer.defaults({ logger: true, bodyParser: true, noCors: false });

server.use(middlewares);

// Special endpoint to test headers, expects those two entries in headers:
// {
//        authorization: 'Basic YWxhZGRpbjpvcGVuc2VzYW1l',
//        'user-agent': 'HTTPFetchTestSuite',
// }
// on error returns 400 with error json
server.get('/headers', (req, res) => {
    const expectedHeaders = {
        authorization: 'Basic YWxhZGRpbjpvcGVuc2VzYW1l',
        'user-agent': 'HTTPFetchTestSuite',
    };
    const errorMsg = { error: true, message: 'no expected headers found', expectedHeaders };
    const successMsg = { error: false, success: true };

    const foundeHadersCnt = Object.keys(req.headers)
        .map(name => expectedHeaders[name.toLowerCase()] === req.headers[name])
        .reduce((acc, v) => (v === true ? acc + 1 : acc), 0);

    if (foundeHadersCnt === Object.keys(expectedHeaders).length) {
        return res.send(successMsg);
    }

    return res.status(400).send(errorMsg);
});

server.use(jsonServer.bodyParser);

server.use(router);
server.listen(process.env.PORT, () => {
    console.log(`JSON Server is running on port ${process.env.PORT}`);
});
