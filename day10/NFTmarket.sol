// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyNFT.sol";
import "./up_data_BERC20.sol";

contract NFTMarket is ITokenReceiver {
    // NFT上架信息结构体
    struct Listing {
        address seller; // 卖家地址
        uint256 price; // 价格(token数量)
        bool active; // 是否在售
    }

    // 状态变量
    MyNFT public nftContract; // NFT合约地址
    BaseERC20 public tokenContract; // ERC20 Token合约地址

    // NFT上架信息: tokenId => 上架信息
    mapping(uint256 => Listing) public listings;

    // 事件
    event NFTListed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );

    event NFTSold(
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 price
    );

    constructor(address _nftContract, address _tokenContract) {
        nftContract = MyNFT(_nftContract);
        tokenContract = BaseERC20(_tokenContract);
    }

    /**
     * @dev 上架NFT功能
     * @param tokenId NFT的tokenId
     * @param price 售价(token数量)
     */
    function list(uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than 0");
        require(
            nftContract.ownerOf(tokenId) == msg.sender,
            "Not the owner of this NFT"
        );
        require(
            nftContract.getApproved(tokenId) == address(this) ||
                nftContract.isApprovedForAll(msg.sender, address(this)),
            "NFT not approved for marketplace"
        );

        // 存储上架信息
        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            active: true
        });

        emit NFTListed(tokenId, msg.sender, price);
    }

    /**
     * @dev 普通的购买NFT功能
     * @param tokenId NFT的tokenId
     */
    function buyNFT(uint256 tokenId) external {
        Listing storage listing = listings[tokenId];
        require(listing.active, "NFT not listed for sale");
        require(listing.seller != msg.sender, "Cannot buy your own NFT");

        uint256 price = listing.price;
        address seller = listing.seller;

        // 标记为已售出
        listing.active = false;

        // 转移token从买家到卖家
        require(
            tokenContract.transferFrom(msg.sender, seller, price),
            "Token transfer failed"
        );

        // 转移NFT从卖家到买家
        nftContract.safeTransferFrom(seller, msg.sender, tokenId);

        emit NFTSold(tokenId, seller, msg.sender, price);
    }

    /**
     * @dev 接收token的回调函数，实现自动购买NFT
     * @param from 发送token的地址
     * @param amount 发送的token数量
     * @param data 额外数据，格式：abi.encode(tokenId)
     */
    function tokensReceived(
        address from,
        uint256 amount,
        bytes calldata data
    ) external override {
        require(
            msg.sender == address(tokenContract),
            "Only token contract can call"
        );

        // 解码额外数据获取NFT信息
        uint256 tokenId = abi.decode(data, (uint256));

        Listing storage listing = listings[tokenId];
        require(listing.active, "NFT not listed for sale");
        require(listing.seller != from, "Cannot buy your own NFT");
        require(amount >= listing.price, "Insufficient token amount");

        address seller = listing.seller;
        uint256 price = listing.price;

        // 标记为已售出
        listing.active = false;

        // 如果支付的token多于要求的价格，退还多余部分
        if (amount > price) {
            require(
                tokenContract.transfer(from, amount - price),
                "Refund transfer failed"
            );
        }

        // 将token转给卖家
        require(
            tokenContract.transfer(seller, price),
            "Payment transfer failed"
        );

        // 转移NFT给买家
        nftContract.safeTransferFrom(seller, from, tokenId);

        emit NFTSold(tokenId, seller, from, price);
    }

    /**
     * @dev 查询NFT上架信息
     */
    function getListing(
        uint256 tokenId
    ) external view returns (address seller, uint256 price, bool active) {
        Listing memory listing = listings[tokenId];
        return (listing.seller, listing.price, listing.active);
    }
}
