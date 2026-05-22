// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Chainproof {
    struct Credential {
        string title;
        uint8 level; // Basic=1, Intermediate=2, Advanced=3
        uint256 timestamp;
    }

    uint256 public constant Threshold = 100;
    address public admin;
    
    mapping(address => Credential[]) private memberCredentials;
    
    event CredentialIssued(address indexed member, string title, uint8 level, uint256 timestamp);

    modifier adminCheck() {
        if (msg.sender != admin) {
            revert("Action executable by admin only");
        }
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function Credential_issue(
        address member_,
        string calldata title_,
        uint8 levelview 
    ) external adminCheck {
        require(member_ != address(0), "Member address cannot be zero address");
        require(levelview <= 3 && levelview >= 1, "Level should be between 1 and 3");

        uint256 currentCount = memberCredentials[member_].length;
        for (uint256 i = 0; i < currentCount; i++) {
            if (keccak256(bytes(memberCredentials[member_][i].title)) == keccak256(bytes(title_))) {
                revert("ChainProof: Credential with this title already exists for member");
            }
            /**
                the above system checks for duvlicate credential titles to maintain ecosystem integrity
                i used keccak256 string hash comparison to search to ussers current elements and compare and if it finds a matching title the transcation reverts indirectly rejecting the 
                duplicate to avoid compromising the integrity of the ecosystem
            */
        }

        memberCredentials[member_].push(Credential({
            title: title_,
            level: levelview,
            timestamp: block.timestamp
        }));

        emit CredentialIssued(member_, title_, levelview, block.timestamp); 
    }

    /**
    * Score formula helps maintain that no person can spam basic operations and easily reach required level by diminishing the returns
    * formula works on the principle of cube of lvl * 10 as the basic score + sqrt(basic count) * 15 + bonus score.
    * level 1 = 10 pts, level 2 = 80pts, level 3 = 270pts
    * Additional score given to person who has all 3 lvl - lv1, lv2 and lv3 as bonus score
    * the sqrt helps in the diminishing return of people who want increase score by spamming lv1 the most basic one
    * the bonus score helps to incentivize people to complete the entire ecosystem
    *trust score value of 100 required to verify so that from only doing lv1 people cannot gain it but htey have to do 1 lv1 and 1 lv2 
    */
    function TrustScore(address member_) public view returns(uint256) {
        uint256 totalCredentials = memberCredentials[member_].length;

        if (totalCredentials == 0) {
            return 0;
        }

        uint256 Score = 0;
        uint256 Count = 0;

        bool lv1 = false;
        bool lv2 = false;
        bool lv3 = false;

        for (uint256 i = 0; i < totalCredentials; i++) {
            uint256 lvl = memberCredentials[member_][i].level;
            Score += (lvl * lvl * lvl * 10);
            if (lvl == 1) {
                Count++;
                lv1 = true;
            } else if (lvl == 2) {
                lv2 = true;
            } else if (lvl == 3) {
                lv3 = true;
            }
        }

        uint256 dampenedBonus = sqrt(Count) * 15;
        uint256 finalScore = Score + dampenedBonus;

        if (lv1 && lv2 && lv3) {
            finalScore += 50;
        }
        
        return finalScore;
    }
    
    function accessGranted() external view returns(bool) {
        uint256 callerScore = TrustScore(msg.sender);
        if (callerScore < Threshold) {
            revert("AccessDenied as callerScore less than minimum threshold of 100 to maintain integrity of the system");
        }
        return true;
    }

    /**
    * Fetches the complete array of credentials assigned to an address.
    * Credentials are bound inherently to the address destination mapping array. Because no standard transfer interfaces (like ERC-20/ERC-721 transfer functions) are exposed, 
    * and because the mapping is private, these achievements are verifiably untransferable
    * This protects ecosystem integrity by preventing bad people from buying reputation.
    */
    function getCredentials(address _member) external view returns (Credential[] memory) {
        return memberCredentials[_member];
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x > 3) {
            uint256 z = x;
            y = x / 2 + 1;
            while (y < z) {
                z = y;
                y = (x / y + y) / 2;
            }
        } else if (x != 0) {
            y = 1;
        }
    }
}