const path     = require('path');
const express  = require('express');
const mongoose = require('mongoose');

const app = express();
const PORT = 3000;
const PROVIDER = process.env.PROVIDER;

var addUserService;
var getUsersService;

if (PROVIDER === 'aws') {
    // Aws has a particular database service (dynamodb) so we have to
    // add custom services for it
    addUserService  = require('./services/dynamoDBServices/add-user');
    getUsersService = require('./services/dynamoDBServices/get-users');
} else {
    // If the provider is not aws we use mongodb as database
    addUserService  = require('./services/mongoServices/add-user');
    getUsersService = require('./services/mongoServices/get-users');

    const DATABASE_URL = process.env.DATABASE_URL || "mongodb://localhost/WebApp";

    mongoose.connect(DATABASE_URL);
    const User = require('./models/User');
    const userRecord = new User({ username: 'Jean' });
    userRecord.save(function (err) {
        if (err) { console.log(err); }
    });
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
