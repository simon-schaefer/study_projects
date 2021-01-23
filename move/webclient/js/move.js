'use strict';

$(function() {
    
    // Move button
    var buttonToggle = false
    
    // fitbit user id
    var myId;
    var myGroup;
    var opponent = {};
    
    // Initialize Firebase
    var config = {
        apiKey: "AIzaSyDHojutYaC3PzLlVomHlWXs0TM0MgbBRqg",
        authDomain: "move-a671d.firebaseapp.com",
        databaseURL: "https://move-a671d.firebaseio.com",
        storageBucket: "",
        messagingSenderId: "835826148269"
    };
    firebase.initializeApp(config);
    
    // All database refenreces
    var userReference;
    var groupsReference = firebase.database().ref('groups');
    var highscoreReference = firebase.database().ref('highscore');
    
    // If user hasn't authed with Fitbit, redirect to Fitbit OAuth Implicit Grant Flow
    var fitbitOAuthAccessToken;
    var fitbitUserId;
    
    if (!window.location.hash) {
        window.location.replace('https://www.fitbit.com/oauth2/authorize?response_type=token&client_id=227Z6B&redirect_uri=http%3A%2F%2Fhz.7jh.de&scope=activity%20heartrate%20location%20profile%20social&expires_in=604800');
    } else {
        var fragmentQueryParameters = {};
        window.location.hash.slice(1).replace(
            new RegExp("([^?=&]+)(=([^&]*))?", "g"),
            function($0, $1, $2, $3) { fragmentQueryParameters[$1] = $3; }
        );
        fitbitOAuthAccessToken = fragmentQueryParameters.access_token;
    }
    
    var processResponse = function(res) {
        if (!res.ok) {
            throw new Error('Fitbit API request failed: ' + res);
        }
        
        var contentType = res.headers.get('content-type')
        if (contentType && contentType.indexOf("application/json") !== -1) {
            return res.json();
        } else {
            throw new Error('JSON expected but received ' + contentType);
        }
    }
    
    var processProfile = function(data) {
        // $.alertSuccess('Connection to fitbit API successful!');
        var user = data['user'];
        myId = user.encodedId;
        userReference = firebase.database().ref('users').child(user.encodedId);
        userReference.child("name").set(user.displayName);
        userReference.child("avatar").set(user.avatar150);
        //userReference.child("group").set("none");
        //userReference.child("contacts").set(["a3cca2b2aa1e3b5b3b5aad99a8529074", "7e716d0e702df0505fc72e2b89467910", "d41d8cd98f00b204e9800998ecf8427e", "87f60ea777b0d9395d5d4ad7ea4be745"]);
        $("#teamMembers").append(
            '<div class="well col-md-4 col-sm4">'
                + '<img class="img-thumbnail" src="' + user.avatar150 + '">'
                + '<p>&nbsp;</p>'
                + '<h2 class="media-heading">' + user.displayName + '</h2>'
                + '<div><strong>ID: </strong>' + user.encodedId + '</div>'
                + '<div>' + user.averageDailySteps + '</div>'
            + '</div>'
        );
    }
    
    var getGroup = function() {
        userReference.once('value').then(function(dataSnapshot) {
            var group = dataSnapshot.val().group;
            if(group === 'null' || group === undefined) {
                $('#team').hide();
                $('#challenge').hide();
                $('#createTeam').show();
            } else {
                groupsReference.child(group).once('value').then(function(dataSnapshot) {
                    myGroup = dataSnapshot.val();
                    myGroup.id = group;
                    showTeam(myGroup);
                    updateMembers();
                });
            }
        });
    }
    
    var printSteps = function(data) {
        data['activities-steps'].forEach(function(measurement) {
            $("#steps").append('<tr><td>' + measurement.dateTime + '</td><td>' + measurement.value + '</td></tr>');
            userReference.child("steps").child(measurement.dateTime).set(measurement.value);
        });
    }
    
    /*
    var printFriends = function(data) {
        data['friends'].forEach(function(friend) {
            var user = friend["user"];
            $("#teamMembers").append(
                '<div class="well col-md-4 col-sm4">'
                    + '<img class="img-thumbnail" src="' + user.avatar150 + '">'
                    + '<p>&nbsp;</p>'
                    + '<h2 class="media-heading">' + user.displayName + '</h2>'
                    + '<div><strong>ID: </strong>' + user.encodedId + '</div>'
                    + '<div>' + user.averageDailySteps + '</div>'
                + '</div>'
            );
        });
    }
    
    var getFriends = function() {
        fetch(
            'https://api.fitbit.com/1/user/-/friends.json',
            {
                headers: new Headers({
                    'Authorization': 'Bearer ' + fitbitOAuthAccessToken
                }),
                mode: 'cors',
                method: 'GET'
            }
        ).then(processResponse)
        .then(printFriends)
        .catch(function(error) {
            console.log(error);
        });
    }
    */
    
    var getSteps = function() {
        fetch(
            'https://api.fitbit.com/1/user/-/activities/steps/date/today/7d.json',
            {
                headers: new Headers({
                    'Authorization': 'Bearer ' + fitbitOAuthAccessToken
                }),
                mode: 'cors',
                method: 'GET'
            }
        ).then(processResponse)
        .then(printSteps)
        .then(getGroup)
        //.then(getFriends)
        .catch(function(error) {
            console.log(error);
        });
    }
    
    fetch(
        'https://api.fitbit.com/1/user/-/profile.json',
        {
            headers: new Headers({
                'Authorization': 'Bearer ' + fitbitOAuthAccessToken
            }),
            mode: 'cors',
            method: 'GET'
        }
    ).then(processResponse)
    .then(processProfile)
    .then(getSteps)
    .catch(function(error) {
        console.log(error);
    });
    
    $('#moveButton').click(function() {
        if(buttonToggle) {
            // Cancel challenge
            $.alertError('Your team looses a level :(');
            
            var levelRef = groupsReference.child(myGroup.id).child('level');
            levelRef.transaction(function(currentLevel) {
                $('#teamRating').html(currentLevel - 1);
                $('span.stars').stars();
                return currentLevel - 1;
            });
            
            $.removeCountdown();
            $('#moveButton').removeClass("btn-danger").addClass("btn-default");
            $('#moveButton').html('<span class="glyphicon glyphicon-hand-up"></span><span>&nbsp; Beat them! Get moving!</span>');
            buttonToggle = false;
        } else {
            var oneWeek = new Date(Date.parse(new Date()) + 7 * 24 * 60 * 60 * 1000);
            $.setCountdown(oneWeek);
            $('#moveButton').removeClass("btn-default").addClass("btn-danger");
            $('#moveButton').html('<span class="glyphicon glyphicon-hand-down"></span><span>&nbsp; Cancel challenge</span>');
            buttonToggle = true;
        }
    });
    
    var showTeam = function(group) {
        $('#teamName').html(group.name);
        $('#teamRating').html(group.level);
        $('span.stars').stars();
        
        $('#team').show();
        $('#challenge').show();
        $('#createTeam').hide();
    }
    
    var generateUUID = function() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx'.replace(/[xy]/g, function(c) {
            var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
            return v.toString(16);
        });
    }
    
    $('#newTeamModal form').on('submit', function() {
        
        var groupId = generateUUID();
        var groupName = $('#newTeamName').val();
        
        myGroup = {
            name: groupName,
            members: [myId],
            level: 0,
            steps: 0
        };
        groupsReference.child(groupId).set(myGroup);
        userReference.child('group').set(groupId);
        
        myGroup.id = groupId;
        
        showTeam(group);
        $('#newTeamModal').modal('hide');
    });
    
    $('.helvetiList ul').on('click', 'a', function(e) {
        e.preventDefault();
        var memberId = $(this).data('id');
        $(this).hide();
        
        myGroup.members.push(memberId);
        groupsReference.child(myGroup.id).set(myGroup);
        firebase.database().ref('users').child(memberId).child('group').set(myGroup.id);
        
        updateMembers();
    });
    
    var updateMembers = function() {
        $("#teamMembers").empty();
        groupsReference.child(myGroup.id).once('value').then(function(dataSnapshot) {
            var totalGroupSteps = 0;
            dataSnapshot.val().members.forEach(function(member) {
                firebase.database().ref('users').child(member).once('value').then(function(snapshot) {
                    
                    var groupSteps = 0;
                    var user = snapshot.val();
                    if(user.steps) {
                        for (var entry in user.steps) {
                            // skip loop if the property is from prototype
                            if(!user.steps.hasOwnProperty(entry)) continue;
                            groupSteps +=  parseInt(user.steps[entry]);
                        }
                    }
                    totalGroupSteps += groupSteps;
                    
                    $("#teamSteps").html(totalGroupSteps);
                    groupsReference.child(myGroup.id).child('steps').set(totalGroupSteps);
                    myGroup.steps = totalGroupSteps;
                    
                    highscoreReference.orderByKey().once('value').then(function(snapshot) {
                       
                        for (var score in snapshot.val()) {
                            // skip loop if the property is from prototype
                            if(!snapshot.val().hasOwnProperty(score)) continue;
                            if(parseInt(score) > myGroup.steps) {
                                opponent.key = score;
                                opponent.value = snapshot.val()[score];
                                 $('#betterTeamSteps').html('"' + score + '"');
                                console.log(snapshot.val()[score]);
                                groupsReference.child(opponent.value).once('value').then(function(snapshot2) {
                                    $('#betterTeamName').html('"' + snapshot2.val().name + '"');
                                });
                            }
                            groupSteps +=  parseInt(snapshot.val()[score]);
                        }
                    });
                    
                    $("#teamMembers").append(
                        '<div class="well col-md-4 col-sm4">'
                            + '<img class="img-thumbnail" src="' + user.avatar + '">'
                            + '<p>&nbsp;</p>'
                            + '<h2 class="media-heading">' + user.name + '</h2>'
                            + '<div><strong>ID: </strong>' + snapshot.key + '</div>'
                        + '</div>'
                    );
                });
            });
            setTimeout(function() {
                highscoreReference.child(totalGroupSteps).set(myGroup.id);
            }, 500);
        });
    }
    
    var getOpponent = function() {
        var nextOne = false;
        highscoreReference.orderByKey().once('value').then(function(snapshot) {
            if(snapshot.key ===  myGroup.steps) {
                nextOne = true;
            }
            if(nextOne) {
                opponent.key = snapshot.key;
                opponent.value = snapshot.val();
                groupsReference.child(opponent.value).once('value').then(function(snapshot) {
                    $('#betterTeamName').html('" + snapshot.val().name + "');
                    $('#betterTeamSteps').html('" + opponent.key + "');
                });
                nextOne = false;
            }
        });
    }

    
    firebase.database().ref('users').on('value', function(dataSnapshot) {
        $('.helvetiList ul').empty();
        dataSnapshot.forEach(function(childSnapshot) {
            var group = childSnapshot.val().group;
            if(group === undefined) {
                $('.helvetiList ul').append('<li><a data-id="' + childSnapshot.key + '" href="#"><strong>[' + childSnapshot.key + ']</strong>  ' + childSnapshot.val().name + '</a></li>');
            }
        });
    });
    
    // Twitter Web Intent bei gewonnener Challenge
    // https://dev.twitter.com/web/tweet-button/web-intent
    // https://twitter.com/intent/tweet?text=Hey!%20%20Check%20out%20the%20latest%20#JamesBond DVD at www.example.com
});
