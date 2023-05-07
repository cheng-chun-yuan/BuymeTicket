// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721 {
    //setting argument
    IERC20 public token; //the second token cost for mint NFT 
    address public owner; //people who construct the contrast
    uint256 public maxSupply; //total supply
    uint256 public nftPrice; // the price of NFT(initial)
    event Refund(uint256 _tokenId,uint256 refundAmount); //to show the event of refund 
    uint256 public nowSupply = 0; //the current mint number
    string private baseURI; // the picture's baseURL
    uint256 public maxPerWallet; //the max NFT number for
    uint256 public nextSaleNumber = 0;
    mapping(address => uint256) public pointBalances ; // Points balance of each user
    mapping(uint256 => bool) public ticketUsed;
    using Strings for uint256; 

    // construct the contrast with specific name symbol maxSupply nftPrice maxPerWallet IERC_token
    constructor(
        uint256 _maxSupply,
        uint256 _nftPrice,
        uint256 _maxPerWallet,
        IERC20 _token
        
    ) ERC721("BuymeTicket", "BmT") {
        maxSupply = _maxSupply;
        nftPrice = _nftPrice;
        owner = msg.sender;
        token = _token;
        maxPerWallet = _maxPerWallet;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "no permission");
        _;
    }
    //checkwalletbalance
    modifier checkbalance() {
        require(msg.sender.balance >= 0.05 ether , "please add more money to your account");
        _;
    }
    // //change TokenURL to 
    function enterTicket(uint256 _tokenId) public {
        // Todo 
        require(msg.sender == owner, "no permission");
        require(_exists(_tokenId), "Token does not exist");
        ticketUsed[_tokenId] = true;
    }

    function used_Ticket(uint256 _tokenId) public view returns (bool) {
        return ticketUsed[_tokenId];
    }
    function _baseURI() internal pure override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmdDzL4Rb2JLcJdQPtNuCJSZ5TTZKwYJXbbjyqVq49iyyL/";
    }
    // //according to how many NFT it mint , change the tokenURL
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        // Todo
        _requireMinted(_tokenId);
        // uint256 picture = balanceOf(ownerOf(_tokenId));
        if(used_Ticket(_tokenId)){
            return string(abi.encodePacked(_baseURI(),"commemorative_ticket.json"));
        }
        // return string(abi.encodePacked("https://gateway.pinata.cloud/ipfs/QmdDzL4Rb2JLcJdQPtNuCJSZ5TTZKwYJXbbjyqVq49iyyL/", picture.toString(), ".json"));
        return string(abi.encodePacked(_baseURI(),"ticket.json"));
    }

    // count how many point(second token) it need to mint
    function calculatePoint(uint256 _mintAmount) public view returns (uint256) {
        //check how many nft in wallet
        uint256 nowAmount = balanceOf(msg.sender);
        uint256 sum = (_mintAmount + 1 + nowAmount * 2) * _mintAmount / 2;
        return sum;
    }

    //use point to prepurchase NFT
    function buyCallOption(uint256 _mintAmount) public payable checkbalance(){
        // uint256 costNum = calculatePoint(_mintAmount);
        // // Check that the user has approved the transfer of tokens to this contract
        // require(token.allowance(msg.sender, address(this)) >= costNum, "Token allowance not set");
        // // Transfer the tokens from the user to this contract
        // require(token.transferFrom(msg.sender, address(this), costNum), "Token transfer failed");
        
        // Credit the user's account with the points
        pointBalances[msg.sender] += _mintAmount;
    }

    function getCallOption() public view checkbalance() returns (uint256){
        return pointBalances[msg.sender];
    }

    //荷蘭拍
    struct Auction {
        uint256 startTime;
        uint256 timeStep;
        uint256 startPrice;
        uint256 endPrice;
        uint256 priceStep;
        uint256 stepNumber;
    }
    Auction public auction; 
    //getcurrentprice
    function getAuctionPrice() public view returns (uint256) {
        Auction memory currentAuction = auction;
        if (block.timestamp < currentAuction.startTime) {
            return currentAuction.startPrice;
        }
        uint256 step = (block.timestamp - currentAuction.startTime) /
            currentAuction.timeStep;
        if (step > currentAuction.stepNumber) {
            step = currentAuction.stepNumber;
        }
        return
            currentAuction.startPrice > step * currentAuction.priceStep
                ? currentAuction.startPrice - step * currentAuction.priceStep
                : currentAuction.endPrice;
    }

    function setAuction(
        uint256 _startTime,
        uint256 _timeStep,
        uint256 _endPrice,
        uint256 _priceStep,
        uint256 _stepNumber
    ) public onlyOwner {
        auction.startTime = _startTime; // 開始時間
        auction.timeStep = _timeStep; // 5 多久扣一次
        auction.startPrice = nftPrice; // 50000000000000000 起始金額
        auction.endPrice = _endPrice; // 10000000000000000 最後金額
        auction.priceStep = _priceStep; // 10000000000000000 每次扣除多少金額
        auction.stepNumber = _stepNumber; // 5 幾個階段
    }
    //Todo : should modify the mint function (mint many NFT simultaneously with one ERC20 token and ETH)
    function auctionmintNFT(uint256 _mintAmount) public payable checkbalance(){
    //new version
        require(getCallOption() >= _mintAmount + balanceOf(msg.sender), "Buy call option first");
        require(
            balanceOf(msg.sender) + _mintAmount <= maxPerWallet,
            "exceed max wallet limit"
        );
        //getAuctionPrice()
        uint256 amountETH = _mintAmount*getAuctionPrice();
		// require(msg.value == amountETH, "Must send the correct amount of ETH");
        require((nowSupply + _mintAmount) <= maxSupply, "sold out");
        
        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 newTokenId = nowSupply + 1;
            nowSupply++;
            _safeMint(msg.sender, newTokenId);
            ticketUsed[newTokenId] = false;
        }
    }

    //get the money from contract
    function withdraw() public payable{
        require(msg.sender == owner, "Only the contract owner can withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }
    //refund
    function refund(uint256 _tokenId) external payable {
        require(_exists(_tokenId), "ERC721A: nonexistent token");
        require(msg.sender == ownerOf(_tokenId), "ERC721A: only token owner can request refund");

        uint256 refundAmount = getAuctionPrice() * 9 / 10;

        // 确保项目方已经向合约转移了足够的以太币来支付退款
        //how to cheak the owner balance?
        require(address(this).balance >= refundAmount, "ERC721A: insufficient funds for refund");
        // 销毁 NFT
        _burn(_tokenId);
        nextSaleNumber++;
        // 发送退款给申请者
        payable(msg.sender).transfer(refundAmount);
        emit Refund(_tokenId, refundAmount);
    }

    //transfer override with price limit
    function _transfer(address from, address to, uint256 tokenId) internal override {
        require(msg.sender == owner, "Transfer not authorized");
        super._transfer(from, to, tokenId);
    }
}