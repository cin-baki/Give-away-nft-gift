pragma solidity 0.8.4;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ERC1155} from '@openzeppelin/contracts/token/ERC1155/ERC1155.sol'; 
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";


contract SipherStatue is ERC1155, Pausable, Ownable {
    uint256 public currentIDtoken = 1;
    mapping(uint256 => string) internal tokenIdToName;
    mapping(address => bool) internal isBlacklist;
    mapping(address => mapping(uint256 => uint256)) internal claimAmount;
    mapping(string => bool) internal isTokennameExist;
    string internal _storeFrontURI;

    // after minnting token, this event will emit
    event mintRecord(address to, uint256 _tokenId, string _tokenname, uint256 amount);
    //  owner() lock an user and emit the event
    event lockUser(address user);
    //  owner() unlock an user and emit the event
    event unlockUser(address user);
    // claim event, emit when user claim token
    event claimRecord(address user, uint256 _tokenId, string _tokenname, uint256 amount);
    // emit an event after burning a comic token.
    event burnRecord(address from, uint256 _tokenId, uint256 amount);

    /**
     * @dev Initiate sipher statue
     */
    constructor() ERC1155("") {
    }
    
    /**
     * @dev modify function to restrict locked user (locked by owner())
     */
    modifier notBlacklist() {
      if (isBlacklist[msg.sender]) {
        revert("You are block by admin, Please contact Sipher agent for more information");
      }    
      _;
    }

    /**
     * @dev mint statue
     * Requirements:
     * - Only for Owner.
     * - Token must exist and not equal to 0
     */
    function mint(uint256 _tokenId, uint256 token_amount) external onlyOwner{
        require(_tokenId <= currentIDtoken, "token not exists");
        require(_tokenId > 0, "token ID is not equal 0");
        _mint(msg.sender, _tokenId, token_amount, "");
        emit mintRecord(msg.sender, _tokenId, tokenIdToName[_tokenId], token_amount);
    }

    /**
     * @dev mint statue to an address
     * Requirements:
     * - Only for Owner.
     * - Token must exist and not equal to 0
     */
    function mintTo(address to, uint256 _tokenId, uint256 token_amount) external onlyOwner{
        require(_tokenId <= currentIDtoken, "token not exists");
        require(_tokenId > 0, "token ID is not equal 0");
        _mint(to, _tokenId, token_amount, "");
        emit mintRecord(to, _tokenId, tokenIdToName[_tokenId], token_amount);
    }


    /**
     * @dev add name of token
     * Requirements:
     * - Only for owner().
     * - Token must not be added before
     */
    function tokenRegistry(string memory _tokenname) external onlyOwner{
        require (!isTokennameExist[_tokenname], "this token name was add before");
        tokenIdToName[currentIDtoken] = _tokenname;
        isTokennameExist[_tokenname] = true;
        currentIDtoken = currentIDtoken + 1;
    }

    /**
     * @dev get name of token by using token id
     * Requirements:
     * - Token must exist and not equal to 0
     */
    function getTokenName(uint256 _tokenId) external view returns (string memory){
        require(_tokenId <= currentIDtoken, "token not exists");
        require(_tokenId > 0, "token ID must not equal 0");
        return tokenIdToName[_tokenId];
    }

    /**
     * @dev user claim the statue
     * Requirements:
     * - Only owner of this token can claim
     * - not be locked by owner()
     * - must have enought balance to claim (blance minus claimed amount >= amount want to claim)
     */
    function claimStatue(uint256 _tokenId, uint256 amount) external notBlacklist{
        require(balanceOf(msg.sender,_tokenId) - claimAmount[msg.sender][_tokenId] >= amount, "not enought balance to claim");
        claimAmount[msg.sender][_tokenId] = claimAmount[msg.sender][_tokenId] + amount;
        emit claimRecord(msg.sender, _tokenId, tokenIdToName[_tokenId], amount);
    }

    function burn(uint256 _tokenId, uint256 amount) external {
        _burn(msg.sender, _tokenId, amount);
        emit burnRecord(msg.sender, _tokenId, amount);
    }

    /**
     * @dev get remain balance after clamming
     */
    function getClaimableToken(address from, uint256 _tokenId) external view returns(uint256){
        return balanceOf(from,_tokenId) - claimAmount[from][_tokenId];
    }

    /**
     * @dev lock user, the user after being locked by owner(), cannot do anything with their assets.
     * Requirements:
     * - Only owner()
     * - owner() cannot lock his own address.
     */
    function adminLockUser(address user) external onlyOwner{
        require(owner() != user, "Hello admin, you lock your own address!");
        isBlacklist[user] = true;
        emit lockUser(user);
    }

    /**
     * @dev unlock user, the user after being unlocked by owner(), they can free to transfer or claim with their assets
     * Requirements:
     * - Only owner()
     */
    function unLockedUser(address user) external onlyOwner{
        isBlacklist[user] = false;
        emit unlockUser(user);
    }

    /**
     * @dev check if user is blacklist
     */
    function isUserBlacklist(address user) external view returns(bool){
        return isBlacklist[user];
    }

    /**
     * @dev approve all asset for an operator
     * Requirements:
     * - not in black list
     */
    function setApprovalForAll(address operator, bool approved) public virtual override notBlacklist{
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev transfer token 
     * Requirements:
     * - not in black list
     * - balance minus amount of claimed token must bigger or equal to transfer amount
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override notBlacklist{
        require(balanceOf(from, id) - claimAmount[from][id] >= amount, "your balance minus amount of claim token is smaller than amount you transfer");
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev batch transfer token 
     * Requirements:
     * - not in black list
     * - balance minus amount of claimed token must bigger or equal to transfer amount
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override notBlacklist{
        for (uint256 i = 0; i < ids.length; i++) {
            require(balanceOf(from, ids[i]) - claimAmount[from][ids[i]] >= amounts[i], "your balance minus amount of claim token is smaller than amount you transfer");
        }
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function setStoreFrontURI(string calldata _uri) external onlyOwner {
        _storeFrontURI = _uri;
    }

    function contractURI() external view returns (string memory) {
        return _storeFrontURI;
    }

    function setNewURI(string memory newuri) external onlyOwner  {
        _setURI(newuri);
    }

    function uri(uint256 _tokenID) public view virtual override returns (string memory) {
        require(_tokenID <= currentIDtoken, "URI query for nonexistent token");
        require(_tokenID > 0, "token ID is start from 1");

        string memory baseURI = super.uri(_tokenID);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(_tokenID))) : "";
    }

}