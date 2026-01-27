
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// 1. INTERFACES
interface IPool {
    function flashLoanSimple(address receiver, address asset, uint256 amount, bytes calldata params, uint16 referralCode) external;
}
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}
interface IRouter {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

contract FlashShark {
    address public owner;
    IPool public POOL;
    IRouter public QUICK_ROUTER;
    IRouter public SUSHI_ROUTER;

    // REAL POLYGON MAINNET ADDRESSES
    address constant AAVE_POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    address constant QUICKSWAP = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address constant SUSHISWAP = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    constructor() {
        owner = msg.sender;
        POOL = IPool(AAVE_POOL);
        QUICK_ROUTER = IRouter(QUICKSWAP);
        SUSHI_ROUTER = IRouter(SUSHISWAP);
    }

    // 2. THE TRIGGER
    function startArbitrage(address tokenToBorrow, uint256 amount) external {
        POOL.flashLoanSimple(address(this), tokenToBorrow, amount, "", 0);
    }

    // 3. THE STRATEGY
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params) external returns (bool) {
        
        // A. Define Path (Token -> WMATIC -> Token)
        address WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        address[] memory pathBuy = new address[](2);
        pathBuy[0] = asset;
        pathBuy[1] = WMATIC;
        address[] memory pathSell = new address[](2);
        pathSell[0] = WMATIC;
        pathSell[1] = asset;

        // B. Approve
        IERC20(asset).approve(QUICKSWAP, amount);
        IERC20(WMATIC).approve(SUSHISWAP, type(uint256).max);

        // C. Trade 1: Buy WMATIC on QuickSwap
        uint[] memory amountsOut = QUICK_ROUTER.swapExactTokensForTokens(amount, 0, pathBuy, address(this), block.timestamp);
        uint256 wmaticBought = amountsOut[1];

        // D. Trade 2: Sell WMATIC on SushiSwap
        uint[] memory finalAmounts = SUSHI_ROUTER.swapExactTokensForTokens(wmaticBought, 0, pathSell, address(this), block.timestamp);
        
        // E. Check Profit
        uint256 finalAssetBalance = IERC20(asset).balanceOf(address(this));
        uint256 amountOwed = amount + premium;

        require(finalAssetBalance > amountOwed, "No Profit");

        // F. Repay & Keep Profit
        IERC20(asset).approve(address(POOL), amountOwed);
        uint256 profit = finalAssetBalance - amountOwed;
        IERC20(asset).transfer(owner, profit);

        return true;
    }
}
