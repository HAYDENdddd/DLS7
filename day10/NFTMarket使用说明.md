# NFTMarket 合约使用说明

## 📋 合约功能概述

这个NFTMarket合约允许用户使用自定义ERC20代币来买卖NFT，支持两种购买方式：
1. **标准购买**：调用`buyNFT()`函数
2. **回调购买**：使用ERC20扩展的`transferWithCallback()`功能

## 🏗️ 合约架构

### 核心组件
- **NFT合约**：符合ERC721标准的NFT
- **Token合约**：带有`transferWithCallback`功能的ERC20扩展代币
- **Market合约**：本NFTMarket合约

### 主要功能
1. `list()` - NFT上架功能
2. `buyNFT()` - 标准购买功能  
3. `tokensReceived()` - 回调购买功能
4. `delist()` - 取消上架
5. `updatePrice()` - 更新价格

## 🚀 使用流程

### 1. 上架NFT

**前置条件**：
- 拥有NFT
- 授权NFTMarket合约操作你的NFT

```solidity
// 1. 授权NFT给market合约
nft.approve(marketAddress, tokenId);
// 或者授权所有NFT
nft.setApprovalForAll(marketAddress, true);

// 2. 上架NFT
market.list(nftContractAddress, tokenId, price);
```

**参数说明**：
- `nftContractAddress`: NFT合约地址
- `tokenId`: 要上架的NFT ID
- `price`: 售价（ERC20代币数量）

### 2. 购买NFT（方式一：标准购买）

```solidity
// 1. 先授权token给market合约
token.approve(marketAddress, price);

// 2. 购买NFT
market.buyNFT(nftContractAddress, tokenId);
```

### 3. 购买NFT（方式二：回调购买）

```solidity
// 使用ERC20扩展的transferWithCallback功能
bytes memory data = abi.encode(nftContractAddress, tokenId);
token.transferWithCallback(marketAddress, amount, data);
```

**优势**：
- 一步完成购买
- 自动处理多付退款
- 更便捷的用户体验

## 📊 事件监听

### NFTListed
```solidity
event NFTListed(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    uint256 price
);
```

### NFTSold
```solidity
event NFTSold(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    address buyer,
    uint256 price
);
```

### NFTDelisted
```solidity
event NFTDelisted(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller
);
```

## 🔍 查询功能

### 查询上架信息
```solidity
(address seller, uint256 price, bool active) = market.getListing(nftContract, tokenId);
```

## ⚠️ 安全特性

### 1. 重入攻击防护
- 使用自定义的`noReentrant`修饰符
- 在状态变更前先标记交易完成

### 2. 权限检查
- 只有NFT拥有者可以上架
- 只有卖家可以取消上架/更新价格
- 不能购买自己的NFT

### 3. 授权检查
- 上架前检查NFT授权状态
- 确保市场合约有权操作NFT

## 💡 使用示例

### 完整交易流程示例

```solidity
// 假设：
// - nft: NFT合约实例
// - token: ERC20代币合约实例  
// - market: NFTMarket合约实例
// - tokenId: 要交易的NFT ID
// - price: 100 个代币

// === 卖家操作 ===
// 1. 授权NFT
nft.approve(address(market), tokenId);

// 2. 上架NFT
market.list(address(nft), tokenId, 100 * 10**18); // 100个代币

// === 买家操作（方式一）===
// 1. 授权代币
token.approve(address(market), 100 * 10**18);

// 2. 购买NFT
market.buyNFT(address(nft), tokenId);

// === 买家操作（方式二）===
// 一步购买
bytes memory data = abi.encode(address(nft), tokenId);
token.transferWithCallback(address(market), 100 * 10**18, data);
```

## 🔧 管理功能

### 取消上架
```solidity
market.delist(nftContractAddress, tokenId);
```

### 更新价格
```solidity
market.updatePrice(nftContractAddress, tokenId, newPrice);
```

## 📝 注意事项

1. **授权重要性**：上架前必须授权NFT给market合约
2. **价格单位**：价格以ERC20代币的最小单位计算（考虑decimals）
3. **回调数据**：使用`transferWithCallback`时，data参数必须是`abi.encode(nftContract, tokenId)`格式
4. **多付处理**：回调购买时如果支付过多，会自动退还差额

## 🎯 最佳实践

1. **前端集成**：监听事件来更新UI状态
2. **价格显示**：注意处理代币的decimals显示
3. **错误处理**：捕获并处理各种revert情况
4. **Gas优化**：批量操作时考虑gas成本

这个NFTMarket合约提供了完整、安全的NFT交易功能，支持现代化的回调购买体验！ 