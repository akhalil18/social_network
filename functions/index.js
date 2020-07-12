const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

exports.onCreateFollower = functions.firestore
    .document("followers/{userId}/userFollowers/{followerId}")
    .onCreate(async (snapshot, context) => {
        console.log("follower created", snapshot.id);

        const userId = context.params.userId;
        const followerId = context.params.followerId;

        // Add posts from followed to following

        // create followed user posts ref
        const followedUserPostsRef = admin
            .firestore()
            .collection('posts')
            .doc(userId)
            .collection('userPosts');

        // create following users timeline ref
        const timelinePostsRef = admin
            .firestore()
            .collection('timeline')
            .doc(followerId)
            .collection('timelinePosts');

        // get the followed user posts
        const querySnapshot = await followedUserPostsRef.get();

        // add each user post to following user timeline
        querySnapshot.forEach(document => {
            if (document.exists) {
                const posId = document.id;
                const posData = document.data();

                timelinePostsRef
                    .doc(posId)
                    .set(posData);
            }
        });

    });

exports.onDeleteUser = functions.firestore
    .document("followers/{userId}/userFollowers/{followerId}")
    .onDelete(async (snapshot, context) => {
        console.log("follower Deleted", snapshot.id);

        const userId = context.params.userId;
        const followerId = context.params.followerId;

        const timelinePostsRef = admin
            .firestore()
            .collection('timeline')
            .doc(followerId)
            .collection('timelinePosts')
            .where("ownerId", "==", userId);

        const querySnapshot = await timelinePostsRef.get();

        querySnapshot.forEach(doc => {
            if (doc.exists) {
                doc.ref.delete();
            }
        });
    });


// add created post to followers time line
exports.onCreatePost = functions.firestore
    .document("posts/{userId}/userPosts/{postId}")
    .onCreate(async (snapshot, context) => {
        console.log("post created", snapshot.id);

        const createdPost = snapshot.data();
        const postId = context.params.postId;
        const userId = context.params.userId;


        // Get all the followers of the user who made the post
        const userFollowersRef = admin.firestore()
            .collection('followers')
            .doc(userId)
            .collection('userFollowers');

        const querySnapshot = await userFollowersRef.get();

        // Add the new post to each follower  timeline
        querySnapshot.forEach(doc => {
            const followerId = doc.id;

            admin
                .firestore()
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .set(createdPost);
        });
    });


exports.onUpdatePost = functions.firestore
    .document("posts/{userId}/userPosts/{postId}")
    .onUpdate(async (change, context) => {
        const postUpdated = change.after.data();
        const postId = context.params.postId;
        const userId = context.params.userId;

        // Get all the followers of the user who made the post
        const userFollowersRef = admin
            .firestore()
            .collection('followers')
            .doc(userId)
            .collection('userFollowers');

        const querySnapshot = await userFollowersRef.get();

        // update the new post to each follower  timeline
        querySnapshot.forEach(doc => {
            const followerId = doc.id;

            admin
                .firestore()
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .get()
                .then(doc => {
                    if (doc.exists) {
                        doc.ref.update(postUpdated);
                    }
                });
        });
    });

exports.onDeletePost = functions.firestore
    .document("posts/{userId}/userPosts/{postId}")
    .onDelete(async (snapshot, context) => {
        const postId = context.params.postId;
        const userId = context.params.userId;

        // Get all the followers of the user who made the post
        const userFollowersRef = admin
            .firestore()
            .collection('followers')
            .doc(userId)
            .collection('userFollowers');

        const querySnapshot = await userFollowersRef.get();

        // delete the  post from each follower  timeline
        querySnapshot.forEach(doc => {
            const followerId = doc.id;

            admin
                .firestore()
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .get()
                .then(doc => {
                    if (doc.exists) {
                        doc.ref.delete();
                    }
                });

        });
    });

exports.onCreateActivityFeedItem = functions.firestore
    .document('feed/{userId}/feedItems/{activityFeedItem}')
    .onCreate(async (snapshot, context) => {
        console.log('Activity feed item created', snapshot.data());

        // Get the user connected to this feed
        const userId = context.params.userId;
        const createdActivityFeedItem = snapshot.data();

        const userRef = admin.firestore().doc(`users/${userId}`);
        const doc = await userRef.get();

        // check if user have a notification token, and send notification if the have a token
        const androidNotificationToken = doc.data().androidNotificationToken;
        if (androidNotificationToken) {
            sendNotification(androidNotificationToken, createdActivityFeedItem);
        } else {
            console.log('No token for the user, cannot send notification');
        }

        function sendNotification(androidNotificationToken, activityFeedItem) {
            let body;

            switch (activityFeedItem.type) {
                case "comment":
                    body = `${activityFeedItem.username} replied: ${activityFeedItem.commentData}`;
                    break;

                case "like":
                    body = `${activityFeedItem.username} liked your post`;
                    break;

                case "follow":
                    body = `${activityFeedItem.username} started following you`;
                    break;

                default:
                    break;
            }

            // create message for push notification
            const message = {
                notification: { body },
                token: androidNotificationToken,
                data: { recipient: userId }
            };

            // send messgae with admin.messaging
            admin
                .messaging()
                .send(message)
                .then(response => {
                    // response is message id 
                    console.log('Message sent successfully', response);
                })
                .catch(error => {
                    console.log('Error sendig message', error);
                });
        }
    }); 