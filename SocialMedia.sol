//SPDX-License-Identifier:UNLICENSED

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SocialMedia is ReentrancyGuard, Pausable {
    event newUserRegister(address indexed userAddress, string UserName);
    event postCreated(address indexed userAddress, uint256 _id, string content);
    event followingUpdated(
        address indexed myAccount,
        address indexed followingAddress
    );
    event followerUpdated(
        address indexed myAccount,
        address indexed followerAddress
    );
    event commented(
        address indexed commenter,
        uint256 postId,
        address indexed postAdress,
        string content
    );
    event Liked(
        address indexed Liker,
        uint256 postId,
        address indexed postAddress
    );
    struct User {
        address UserAddress;
        string UserName;
        string bio;
        uint256 follower;
        uint256 following;
        uint256 totalPost;
        bool isRegister;
    }
    struct Post {
        uint256 postId;
        string content;
        uint256 likesCount;
        uint256 commentsCount;
    }

    struct Comment {
        address commenter;
        string content;
        uint256 timestamp;
    }

    mapping(address => User) public user_profile;
    address[] public registeredUsers;

    mapping(address => address[]) public allFollowing;
    mapping(address => address[]) public allFollowers;

    uint256 public nextPostId;

    mapping(address => mapping(uint256 => Post)) public posts;
    mapping(address => uint256[]) public userPosts;

    mapping(address => mapping(address => bool)) public isFollowing;

    // Mapping from post owner to post ID to liker address to boolean
    mapping(address => mapping(uint256 => mapping(address => bool)))
        public postLikes;
    // Mapping from post owner to post ID to array of comments
    mapping(address => mapping(uint256 => Comment[])) public postComments;

    // Mapping from user address to a mapping of postId to a boolean indicating if the user liked the post
    mapping(address => mapping(uint256 => bool)) public hasLiked;

    function register(string memory bio, string memory username)
        external
        nonReentrant
        whenNotPaused
    {
        require(
            !user_profile[msg.sender].isRegister,
            "User is Already Register"
        );
        require(bytes(username).length > 0, "username can not be empty");

        user_profile[msg.sender] = User({
            UserAddress: msg.sender,
            UserName: username,
            bio: bio,
            follower: 0,
            following: 0,
            totalPost: 0,
            isRegister: true
        });
        registeredUsers.push(msg.sender);
        emit newUserRegister(msg.sender, username);
    }

    function createPost(string memory _content)
        external
        whenNotPaused
        nonReentrant
    {
        require(user_profile[msg.sender].isRegister, "You aren't registered");
        require(bytes(_content).length > 0, "Content cannot be empty");
        require(
            userPosts[msg.sender].length < 10,
            "Maximum of 10 posts allowed"
        );

        uint256 postId = nextPostId++;
        posts[msg.sender][postId] = Post({
            postId: postId,
            content: _content,
            likesCount: 0,
            commentsCount: 0
        });
        userPosts[msg.sender].push(postId);
        user_profile[msg.sender].totalPost++;

        emit postCreated(msg.sender, postId, _content);
    }

    function deletePost(uint256 postId) external whenNotPaused {
        require(user_profile[msg.sender].isRegister, "User not registered");
        require(
            posts[msg.sender][postId].postId == postId,
            "Post does not exist"
        );

        delete posts[msg.sender][postId];
        user_profile[msg.sender].totalPost--;

        uint256[] storage postIds = userPosts[msg.sender];
        for (uint256 i = 0; i < postIds.length; i++) {
            if (postIds[i] == postId) {
                postIds[i] = postIds[postIds.length - 1];
                postIds.pop();
                break;
            }
        }

        // Delete associated comments
        delete postComments[msg.sender][postId];
    }

    function addComment(
        address postOwner,
        uint256 postId,
        string memory content
    ) external whenNotPaused {
        require(user_profile[msg.sender].isRegister, "User not registered");
        require(
            posts[postOwner][postId].postId == postId,
            "Post does not exist"
        );
        require(bytes(content).length > 0, "Comment cannot be empty");

        Comment memory newComment = Comment({
            commenter: msg.sender,
            content: content,
            timestamp: block.timestamp
        });

        postComments[postOwner][postId].push(newComment);
        posts[postOwner][postId].commentsCount++;

        emit commented(msg.sender, postId, postOwner, content);
    }

    function deleteComment(
        address postOwner,
        uint256 postId,
        uint256 commentIndex
    ) external whenNotPaused {
        require(user_profile[msg.sender].isRegister, "User not registered");
        require(
            posts[postOwner][postId].postId == postId,
            "Post does not exist"
        );
        require(
            postComments[postOwner][postId].length > commentIndex,
            "Invalid comment index"
        );
        require(
            postComments[postOwner][postId][commentIndex].commenter ==
                msg.sender,
            "Not your comment"
        );

        uint256 lastIndex = postComments[postOwner][postId].length - 1;
        if (commentIndex != lastIndex) {
            postComments[postOwner][postId][commentIndex] = postComments[
                postOwner
            ][postId][lastIndex];
        }
        postComments[postOwner][postId].pop();
        posts[postOwner][postId].commentsCount--;
    }

    function follow(address friendAddress) external whenNotPaused {
        require(user_profile[msg.sender].isRegister, "you are not registerer");
        require(
            user_profile[friendAddress].isRegister ||
                friendAddress != address(0),
            "You friend address is not valid"
        );

        require(friendAddress != msg.sender, "you cant follow yourself");
        require(
            isFollowing[msg.sender][friendAddress] == false,
            "you are alredy following this user"
        );

        user_profile[friendAddress].follower++;
        user_profile[msg.sender].following++;
        allFollowing[msg.sender].push(friendAddress);
        allFollowers[friendAddress].push(msg.sender);

        isFollowing[msg.sender][friendAddress] = true;

        emit followingUpdated(msg.sender, friendAddress);
        emit followerUpdated(friendAddress, msg.sender);
    }

    //  user -> follow krke unfollow v krksta h

    function unfollow(address unfollowAddress) external whenNotPaused {
        require(user_profile[msg.sender].isRegister);
        require(
            user_profile[unfollowAddress].isRegister ||
                unfollowAddress != address(0)
        );
        require(
            isFollowing[msg.sender][unfollowAddress] == true,
            "you are not following this user"
        );

        user_profile[msg.sender].following--;
        user_profile[unfollowAddress].follower--;

        isFollowing[msg.sender][unfollowAddress] = false;

        for (uint256 i = 0; i < allFollowing[msg.sender].length; i++) {
            if (allFollowing[msg.sender][i] == unfollowAddress) {
                allFollowing[msg.sender][i] = allFollowing[msg.sender][
                    allFollowing[msg.sender].length - 1
                ];

                allFollowing[msg.sender].pop();

                break;
            }
        }

        for (uint256 i = 0; i < allFollowers[unfollowAddress].length; i++) {
            if (allFollowers[unfollowAddress][i] == msg.sender) {
                allFollowers[unfollowAddress][i] = allFollowers[
                    unfollowAddress
                ][allFollowers[unfollowAddress].length - 1];

                allFollowers[msg.sender].pop();

                break;
            }
        }

        emit followingUpdated(msg.sender, unfollowAddress);
        emit followerUpdated(unfollowAddress, msg.sender);
    }

    function likePost(address postOwner, uint256 postId) external nonReentrant {
        require(user_profile[msg.sender].isRegister, "User not registered");
        require(
            posts[postOwner][postId].postId == postId,
            "Post does not exist"
        );
        require(!hasLiked[msg.sender][postId], "Already liked this post");

        hasLiked[msg.sender][postId] = true;
        posts[postOwner][postId].likesCount++;

        emit Liked(msg.sender, postId, postOwner);
    }

    function unlikePost(address postOwner, uint256 postId)
        external
        nonReentrant
    {
        require(user_profile[msg.sender].isRegister, "User not registered");
        require(
            posts[postOwner][postId].postId == postId,
            "Post does not exist"
        );
        require(hasLiked[msg.sender][postId], "You have not liked this post");

        hasLiked[msg.sender][postId] = false;
        posts[postOwner][postId].likesCount--;
    }

    function getAllRegisteredUsers() external view returns (address[] memory) {
        return registeredUsers;
    }

    function getFollowing(address user)
        external
        view
        returns (address[] memory)
    {
        return allFollowing[user];
    }

    function getUserPosts(address user) external view returns (Post[] memory) {
        uint256[] storage postIds = userPosts[user];
        Post[] memory userPostList = new Post[](postIds.length);
        for (uint256 i = 0; i < postIds.length; i++) {
            userPostList[i] = posts[user][postIds[i]];
        }
        return userPostList;
    }

    function getFollowers(address user)
        external
        view
        returns (address[] memory)
    {
        return allFollowers[user];
    }

    function getUserProfile(address user)
        external
        view
        returns (
            address UserAddress,
            string memory UserName,
            string memory bio,
            uint256 follower,
            uint256 following,
            uint256 totalPost,
            bool isRegister
        )
    {
        User memory u = user_profile[user];
        return (
            u.UserAddress,
            u.UserName,
            u.bio,
            u.follower,
            u.following,
            u.totalPost,
            u.isRegister
        );
    }

    function getLikesCount(address postOwner, uint256 postId)
        external
        view
        returns (uint256)
    {
        require(
            posts[postOwner][postId].postId == postId,
            "Post does not exist"
        );
        return posts[postOwner][postId].likesCount;
    }

    function getComments(address postOwner, uint256 postId)
        external
        view
        returns (Comment[] memory)
    {
        return postComments[postOwner][postId];
    }
}
