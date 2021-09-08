
require('dotenv/config');

// https://github.com/typicode/json-server
const jsonServer = require('json-server');
// Copy of data from from http://jsonplaceholder.typicode.com/db
const db = require('./json-server-db.json');

const server = jsonServer.create();
const router = jsonServer.router(db);
const middlewares = jsonServer.defaults({ logger: true, bodyParser: true, noCors: false });

server.use(middlewares);
server.get('/echo', (req, res) => {
    res.jsonp(req.query);
});

server.use(jsonServer.bodyParser);

server.use(router);
server.listen(process.env.PORT, () => {
    console.log(`JSON Server is running on port ${process.env.PORT}`);
});
