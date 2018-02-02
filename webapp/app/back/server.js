const path     = require('path');
const express  = require('express');
const mongoose = require('mongoose');
const addUser  = require('./services/mongoServices/add-user');
const getUsers = require('./services/mongoServices/get-users');

const app = express();
const PORT = 3000;
const DATABASE_URL = process.env.DATABASE_URL || "mongodb://localhost/WebApp";

mongoose.connect(DATABASE_URL);
const User = require('./models/User');
const userRecord = new User({ username: 'Jean' });
userRecord.save(function (err) {
    if (err) { console.log(err); }
});

app.use(express.static(path.resolve(__dirname, '..', 'front')));
app.use(express.urlencoded({extended: true}));
app.use(express.json());

app.get('/users', function (req, res) {
    getUsers()
        .then(function(data) {
            res.send(data);
        })
        .catch(function() {
            res.status(500).send('Ooops!');
        });
});

// POST method route
app.post('/user', function (req, res) {
    addUser(req.body.username)
        .then(function() {
            res.send({msg: 'User added successfully'});
        })
        .catch(function() {
            res.status(500).send('Ooops!');
        });
});

app.listen(PORT, () => console.log(`Terraform POC app running on port ${PORT}!`));
