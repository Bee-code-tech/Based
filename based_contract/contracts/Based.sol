// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./UserProfileLib.sol";
import "./CommunityLib.sol";
import "./ProjectLib.sol";
import "./PostLib.sol";
import "contracts/IERC20.sol";
import "contracts/BasedErrors.sol";

contract Based {
    IERC20 immutable paymentToken;
    address immutable owner;

    using UserProfileLib for *;
    using CommunityLib for *; // Enable use of library functions
    using ProjectLib for *;
    using PostLib for *;

    mapping(address => UserProfileLib.User) users;
    mapping(bytes32 => CommunityLib.Community) communities;
    mapping(address => mapping(address => UserProfileLib.User)) follows;
    mapping(bytes32 => mapping(address => CommunityLib.Member)) members;
    mapping(address => mapping(bytes32 => CommunityLib.Community)) myCommunities;
    mapping(bytes32 => ProjectLib.Project) projects;
    mapping(bytes32 => mapping(address => ProjectLib.ProjectMember)) projectMembers;
    mapping(bytes32 => PostLib.Post) posts;
    mapping(bytes32 => mapping(bytes32 => PostLib.Comment)) userComment;

    event Deployed(address contractAddress);

    constructor(address _owner, address _paymentTokenAddress) {
        if (_owner == address(0) || _paymentTokenAddress == address(0))
            revert BasedErrors.NOT_ALLOWED(address(0));

        owner = _owner;
        paymentToken = IERC20(_paymentTokenAddress);

        emit Deployed(address(this));
    }

    modifier addressZeroCheck() {
        msg.sender.addressZeroCheck();
        _;
    }

    modifier isAUser() {
        if (!users._isUser(msg.sender))
            revert BasedErrors.NOT_A_USER(msg.sender);
        _;
    }

    function userRegisters(
        UserProfileLib.UserDetails memory _userDetails
    ) external addressZeroCheck {
        uint _balance = paymentToken.balanceOf(msg.sender);
        if (_balance < 2) revert BasedErrors.INSUFFICIENT(_balance);

        if (!paymentToken.transfer(msg.sender, address(this), 2))
            revert BasedErrors.REGISTRATION_FAILED();

        users._registerUser(msg.sender, _userDetails);
    }

    function getUser(
        address _caller
    ) external view returns (UserProfileLib.User memory) {
        return users._getUser(_caller);
    }

    function updateUsername(
        string memory _username
    ) external addressZeroCheck isAUser {
        uint256 changeTime = users[msg.sender].updateUsername + 30 days;

        if (changeTime > block.timestamp)
            revert BasedErrors.CANNOT_UPDATE_USERNAME_YET(changeTime);

        users._updateUsername(msg.sender, _username);
    }

    function updatePicture(
        string memory _userPicture
    ) external addressZeroCheck isAUser {
        users._updatePicture(msg.sender, _userPicture);
    }

    function followAUser(
        address _userToFollow
    ) external addressZeroCheck isAUser {
        UserProfileLib._followAUser(users, follows, msg.sender, _userToFollow);
    }

    function unfollowAUser(
        address _userToUnFollow
    ) external addressZeroCheck isAUser {
        UserProfileLib._unfollowAUser(
            users,
            follows,
            msg.sender,
            _userToUnFollow
        );
    }

    function getMyFollowers()
        external
        view
        returns (UserProfileLib.User[] memory _myFollowers)
    {
        return UserProfileLib._getMyFollowers(users, follows, msg.sender);
    }

    function getMyFollowings()
        external
        view
        returns (UserProfileLib.User[] memory _myFollowers)
    {
        return UserProfileLib._getMyFollowing(users, follows, msg.sender);
    }

    //=====

    function createCommunity(
        string memory _communityName,
        string memory _description
    ) external addressZeroCheck isAUser {
        CommunityLib._createCommunity(
            communities,
            msg.sender,
            _communityName,
            _description
        );
    }

    function getCommunity(
        bytes32 _commId
    ) external view returns (CommunityLib.Community memory) {
        return communities._getCommunity(_commId);
    }

    function getMyCommunities(
        address _userAdd
    ) external view returns (CommunityLib.Community[] memory) {
        UserProfileLib.User memory _user = users[_userAdd];

        CommunityLib.Community[] memory _comm = new CommunityLib.Community[](
            _user.myCommunitiesId.length
        );

        for (uint256 i = 0; i < _user.myCommunitiesId.length; i++) {
            _comm[i] = myCommunities[_userAdd][_user.myCommunitiesId[i]];
        }

        return _comm;
    }

    function joinCommunity(bytes32 _commId) external addressZeroCheck isAUser {
        CommunityLib._joinCommunity(
            communities,
            members,
            myCommunities,
            msg.sender,
            _commId
        );
        users[msg.sender].myCommunitiesId.push(_commId);
    }

    function getCommunityMember(
        bytes32 _commId,
        address _member
    ) external view returns (CommunityLib.Member memory) {
        return members._getCommunityMember(_commId, _member);
    }

    function removeCommunityMember(
        address _member,
        bytes32 _commId
    ) external addressZeroCheck isAUser {
        CommunityLib._removeMember(
            communities,
            members,
            myCommunities,
            msg.sender,
            _member,
            _commId
        );
    }

    function addCommunityMember(
        address _member,
        bytes32 _commId
    ) external addressZeroCheck isAUser {
        CommunityLib._addMember(
            communities,
            members,
            myCommunities,
            msg.sender,
            _member,
            _commId
        );
    }

    function memberLeavesCommunity(
        bytes32 _commId
    ) external addressZeroCheck isAUser {
        CommunityLib._memberLeaves(
            communities,
            members,
            myCommunities,
            _commId,
            msg.sender
        );
    }

    //======
    function createProject(
        ProjectLib.ProjectData memory _projectData
    ) external addressZeroCheck isAUser {
        ProjectLib._createProject(projects, msg.sender, _projectData);
    }

    function joinProject(
        bytes32 _projId,
        string memory _portfolioLink,
        string memory _emailAddress
    ) external addressZeroCheck isAUser {
        ProjectLib._joinProject(
            projects,
            projectMembers,
            msg.sender,
            _projId,
            _portfolioLink,
            _emailAddress
        );
    }

    function leaveProject(bytes32 _projId) external addressZeroCheck isAUser {
        ProjectLib._leaveProject(projects, projectMembers, msg.sender, _projId);
    }

    function getProject(
        bytes32 _projId
    ) external view returns (ProjectLib.Project memory) {
        return projects._getProject(_projId);
    }

    function getProjectMember(
        bytes32 _projId,
        address _member
    ) external view returns (ProjectLib.ProjectMember memory) {
        return projectMembers._getProjectMember(_projId, _member);
    }

    //======

    function createPost(
        string memory _post,
        string memory _postImage
    ) external addressZeroCheck isAUser {
        posts._createPost(msg.sender, _post, _postImage);
    }

    function commentOnPost(bytes32 _postId, string memory _comment) external {
        PostLib._commentOnPost(
            posts,
            userComment,
            msg.sender,
            _postId,
            _comment
        );
    }

    function getUserComment(
        bytes32 _postId,
        bytes32 _commentId
    ) public view returns (PostLib.Comment memory) {
        return userComment._getUserComment(_postId, _commentId);
    }

    function likePost(bytes32 _postId) external addressZeroCheck isAUser {
        posts._likePost(_postId);
    }
}
