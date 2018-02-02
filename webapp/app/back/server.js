const path     = require('path');
const express  = require('express');
const mongoose = require('mongoose');

const app = express();
const PORT = 3000;
const PROVIDER = process.env.PROVIDER;

var addUserService;
var getUsersService;

if (PROVIDER === 'aws') {
    // Aws has a particular database service (DynamoDB) so we have to
    // add custom services for it.
    addUserService  = require('./services/dynamoDBServices/add-user');
    getUsersService = require('./services/dynamoDBServices/get-users');
} else if (PROVIDER === 'azure') {
    // Azure has a mongodb database (CosmosDB).
    addUserService  = require('./services/mongoServices/add-user');
    getUsersService = require('./services/mongoServices/get-users');

    const DATABASE_USER = process.env.DATABASE_USER;
    const DATABASE_PASSWORD = process.env.DATABASE_PASSWORD;
    const DATABASE_URL = `mongodb://${DATABASE_USER}.documents.azure.com:10255/WebApp?ssl=true`;

    mongoose.connect(DATABASE_URL, {
        auth: {
            user: DATABASE_USER,
            password: DATABASE_PASSWORD
        }
    });
} else {
    addUserService  = require('./services/mongoServices/add-user');
    getUsersService = require('./services/mongoServices/get-users');

    mongoose.connect('mongodb://localhost/WebApp');
}

app.use(express.static(path.resolve(__dirname, '..', 'front')));
app.use(express.urlencoded({extended: true}));
app.use(express.json());

app.get('/users', function (req, res) {
    getUsersService()
        .then(function(data) {
            res.send(data);
        })
        .catch(function() {
            res.status(500).send('Ooops!');
        });
});

// POST method route
app.post('/user', function (req, res) {
    addUserService(req.body.username)
        .then(function() {
            res.send({msg: 'User added successfully'});
        })
        .catch(function() {
            res.status(500).send('Ooops!');
        });
});

app.listen(PORT, () => console.log(`Terraform POC app running on ${PROVIDER} provider on port ${PORT}!`));
