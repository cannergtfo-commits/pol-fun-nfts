// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice 100-piece ERC-721. The deployer mints the whole set once. No further mint.
contract FunDrop {
    string public name;
    string public symbol;
    string public baseURI;
    address public immutable deployer;
    uint256 public constant MAX = 100;
    uint256 public totalSupply;
    mapping(uint256 => address) private _owner;
    mapping(address => uint256) private _balance;
    mapping(uint256 => address) private _tokenApproval;
    mapping(address => mapping(address => bool)) private _operatorApproval;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    error NotDeployer();
    error AlreadyMinted();
    error BadId();
    error NotOwner();
    error NotApproved();

    constructor(string memory name_, string memory symbol_, string memory baseURI_) {
        name = name_;
        symbol = symbol_;
        baseURI = baseURI_;
        deployer = msg.sender;
    }

    function mintAll(address to) external {
        if (msg.sender != deployer) revert NotDeployer();
        if (totalSupply != 0) revert AlreadyMinted();
        if (to == address(0)) revert BadId();
        for (uint256 id = 1; id <= MAX; id++) {
            _owner[id] = to;
            emit Transfer(address(0), to, id);
        }
        _balance[to] = MAX;
        totalSupply = MAX;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        if (_owner[tokenId] == address(0)) revert BadId();
        return string.concat(baseURI, _u(tokenId), ".json");
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address o = _owner[tokenId];
        if (o == address(0)) revert BadId();
        return o;
    }

    function balanceOf(address account) external view returns (uint256) {
        if (account == address(0)) revert BadId();
        return _balance[account];
    }

    function approve(address to, uint256 tokenId) external {
        address o = ownerOf(tokenId);
        if (msg.sender != o && !_operatorApproval[o][msg.sender]) revert NotApproved();
        _tokenApproval[tokenId] = to;
        emit Approval(o, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        if (_owner[tokenId] == address(0)) revert BadId();
        return _tokenApproval[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        _operatorApproval[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) external view returns (bool) {
        return _operatorApproval[account][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        address o = ownerOf(tokenId);
        if (o != from) revert NotOwner();
        if (to == address(0)) revert BadId();
        if (msg.sender != o && msg.sender != _tokenApproval[tokenId] && !_operatorApproval[o][msg.sender]) revert NotApproved();
        _tokenApproval[tokenId] = address(0);
        _balance[from] -= 1;
        _balance[to] += 1;
        _owner[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata) external {
        transferFrom(from, to, tokenId);
    }

    function supportsInterface(bytes4 id) external pure returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd || id == 0x5b5e139f;
    }

    function _u(uint256 v) private pure returns (string memory) {
        if (v == 0) return "0";
        uint256 n;
        uint256 x = v;
        while (x != 0) { n++; x /= 10; }
        bytes memory b = new bytes(n);
        while (v != 0) { b[--n] = bytes1(uint8(48 + v % 10)); v /= 10; }
        return string(b);
    }
}
