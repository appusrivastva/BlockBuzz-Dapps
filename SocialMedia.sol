//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SocialMedia {
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

    mapping(address => User) public user_profile;
    address[] public registeredUsers;

    mapping(address => address[]) public allFollowing;
    mapping(address => address[]) public allFollowers;
    mapping(address => Post[]) public posts;
    mapping(address => mapping(address => bool)) public isFollowing;

    // all  liked address-> ek post address hoga  uski  id ->

    //   function  for  registration

    //   function  for  registration

    function register(string memory bio, string memory username) external {
        //  user is   already register or not
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

    // testing  ->  every user  call this  function  only one time
    //  if secong time called by someone they will give
    //  a an error msg which  is u are alredy registered.
    // and also if u are   adding empty string  in the user name then  the error-> username can't be  empty

    //   function   -> user can call the function to create post
    //  post  id  and post content
    //  har user ka  multiple post  hoga
    // addresss-> post[]

    function createPost(string memory _content) external {
        require(
            user_profile[msg.sender].isRegister,
            "You aren't doing any registration"
        );
        require(
            bytes(_content).length > 0,
            "can not add empty string in content"
        );
        require(
            posts[msg.sender].length < 10,
            "you can add upto 10 posts only"
        );

        uint256 _postId = posts[msg.sender].length;

        posts[msg.sender].push(
            Post({
                postId: _postId,
                content: _content,
                likesCount: 0,
                commentsCount: 0
            })
        );

        // update postCount
        user_profile[msg.sender].totalPost++;
        emit postCreated(msg.sender, _postId, _content);
    }

    // ab user krega   add friend

    //  address->    following[]->  address-> address[]
    // check friendAddress-> register h ya ni h

    //  agar hain toh usko follow krne denge

    function follow(address friendAddress) external {
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

    function unfollow(address unfollowAddress) external {
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

        //  remove   unfollow address from the array  following
        //  mere following list se  vo address remove hoga
        for (uint256 i = 0; i < allFollowing[msg.sender].length; i++) {
            if (allFollowing[msg.sender][i] == unfollowAddress) {
                // //  remove this element from the array
                // delete allFollowing[msg.sender][i];

                allFollowing[msg.sender][i] = allFollowing[msg.sender][
                    allFollowing[msg.sender].length - 1
                ];

                // swap and pop

                allFollowing[msg.sender].pop();

                break;
            }
        }

        // remove my adress to  follower list of unfollow address

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

    function addLikes(address postAddress, uint256 _postId) external {
        require(user_profile[msg.sender].isRegister);

        require(posts[postAddress].length > 0, "you have not posted anything");
        Post[] storage p = posts[postAddress];
        p[_postId].likesCount++;
    }

    function getAllRegisteredUsers() external view returns (address[] memory) {
        return registeredUsers;
    }

    function getUserPosts(address user) external view returns (Post[] memory) {
        return posts[user];
    }

    function getFollowing(address user)
        external
        view
        returns (address[] memory)
    {
        return allFollowing[user];
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
}
