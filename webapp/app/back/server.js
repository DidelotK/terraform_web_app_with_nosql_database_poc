const path = require('path');
const express = require('express');
const addUser = require('./services/add-user');
const getUsers = require('./services/get-users');

const app = express();
const PORT = 3000;

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
