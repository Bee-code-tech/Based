// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "contracts/BasedErrors.sol";

library UserProfileLib {

    struct User {
        string fullName;
        string bio;
        string portfolioLink;
        string[] skills;
        string country;
        address[] followers;
        uint256 noOfFollowers;
        uint256 noOfFollowing;
        address[] following;
        address userAddress;
        string userPicture;
        string username;
        uint256 updateUsername;
        uint256 registeredAt;
        bytes32[] myCommunitiesId;
    }

    struct UserDetails {
        string fullName;
        string bio;
        string portfolioLink;
        string[] skills;
        string country;
        string userPicture;
        string username;
    }//["Michael Dean", "I am a smart contract developer", "htts://myprofilelink.com", ["Java", "Solidity", "Cairo", "Rust"], "Nigeria", "my picture", "dean8ix"]
//0x9d17ecd2f2f42067ba2eaa3c8d43c1017db6e21cddf05b03357d2f3d4bd4b4ff

    event Registered(address indexed userAddress, string indexed username);
    event UsernameUpdated(string indexed username, uint256 indexed timeOfChange);
    event PictureUpdated(address indexed user, string indexed _userPicture);

    function addressZeroCheck(address _add) internal pure {
        if (_add == address(0)) 
            revert BasedErrors.NOT_ALLOWED(address(0));
    }

    function _registerUser(
        mapping(address => User) storage users,
        address _userAddress,
        UserDetails memory _userDetails
    ) internal {

        User storage newUser = users[_userAddress];
        
        newUser.userAddress = _userAddress;
        newUser.fullName = _userDetails.fullName;
        newUser.bio = _userDetails.bio;
        newUser.portfolioLink = _userDetails.portfolioLink;
        newUser.skills = _userDetails.skills;
        newUser.country = _userDetails.country;    
        newUser.userPicture = _userDetails.userPicture;
        newUser.username = _userDetails.username;
        newUser.registeredAt = block.timestamp;
        
        emit Registered(newUser.userAddress, newUser.username);
    }

    function _updateUsername(
        mapping(address => User) storage users,
        address _userAddress,
        string memory _newUsername
    ) internal {

        User storage _user = users[_userAddress];

        _user.username = _newUsername;

        uint256 timeOfChange = block.timestamp;
        _user.updateUsername = timeOfChange;

        emit UsernameUpdated(_newUsername, timeOfChange);
    }

    function _updatePicture(
        mapping(address => User) storage users,
        address _userAddress,
        string memory _newPicture
    ) internal {

        users[_userAddress].userPicture = _newPicture;

        emit PictureUpdated(_userAddress, _newPicture);
    }

    function _getUser(
        mapping(address => User) storage users,
        address _user
    ) public view returns (User memory) {
        return users[_user];
    }

    function _isUser(mapping(address => User) storage users, address _caller) public view returns(bool) {
        if (users[_caller].userAddress == address(0))
            return false;
        
        return true;
    }

    function _followAUser(
        mapping(address => User) storage users,
        mapping (address => mapping (address => UserProfileLib.User)) storage follows,
        address _me,
        address _userToFollow
        ) public {

            if (follows[_userToFollow][_me].userAddress == address(0)) {

                follows[_userToFollow][_me] = users[_me];

                User storage _acctToFollow = users[_userToFollow];
                User storage _myAccount = users[_me];

                _acctToFollow.noOfFollowers += 1;
                _acctToFollow.followers.push(_me);

                _myAccount.noOfFollowing += 1;
                _myAccount.following.push(_userToFollow);
            }
        }

        function _unfollowAUser(
        mapping(address => User) storage users,
        mapping (address => mapping (address => UserProfileLib.User)) storage follows,
        address _me,
        address _userToUnFollow
        ) public {

            if (follows[_userToUnFollow][_me].userAddress != address(0)) {

                delete follows[_userToUnFollow][_me];
                users[_userToUnFollow].noOfFollowers -= 1;

                users[_me].noOfFollowing -= 1;

            }
        }

        function _getMyFollowers(
            mapping(address => User) storage users,
            mapping (address => mapping (address => UserProfileLib.User)) storage follows,
            address _me
        ) public view returns (User[] memory _myFollowers) {
            User memory _myAccount = users[_me];

            uint256 noOfFollowers = _myAccount.noOfFollowers;

            _myFollowers = new User[](noOfFollowers);

            for (uint256 i = 0; i < noOfFollowers; i++) {
                _myFollowers[i] = follows[_me][_myAccount.followers[i]];
            }
            return _myFollowers;
        }

        function _getMyFollowing(
            mapping(address => User) storage users,
            mapping (address => mapping (address => UserProfileLib.User)) storage follows,
            address _me
        ) public view returns (User[] memory _myFollowings) {
            User memory _myAccount = users[_me];

            uint256 noOfFollowers = _myAccount.noOfFollowers;

            _myFollowings = new User[](noOfFollowers);

            for (uint256 i = 0; i < noOfFollowers; i++) {
                _myFollowings[i] = follows[_myAccount.following[i]][_me];
            }
            return _myFollowings;
        }

   
}
