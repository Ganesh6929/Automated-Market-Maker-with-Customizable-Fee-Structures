// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CustomFeeAMM
 * @dev Automated Market Maker with customizable fee for each pool
 */
contract CustomFeeAMM {
    struct Pool {
        address tokenA;
        address tokenB;
        uint256 reserveA;
        uint256 reserveB;
        uint256 feeBasisPoints; // Fee in basis points (e.g., 30 = 0.3%)
        bool exists;
    }

    uint256 public poolCount;
    mapping(uint256 => Pool) public pools;

    event PoolCreated(uint256 poolId, address tokenA, address tokenB, uint256 feeBps);
    event LiquidityAdded(uint256 poolId, uint256 amountA, uint256 amountB);
    event Swapped(uint256 poolId, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    /**
     * @dev Create a new liquidity pool with custom fee
     */
    function createPool(address _tokenA, address _tokenB, uint256 _feeBasisPoints) external returns (uint256) {
        require(_tokenA != _tokenB, "Tokens must be different");
        require(_feeBasisPoints <= 1000, "Fee too high"); // Max 10%
        poolCount++;

        pools[poolCount] = Pool({
            tokenA: _tokenA,
            tokenB: _tokenB,
            reserveA: 0,
            reserveB: 0,
            feeBasisPoints: _feeBasisPoints,
            exists: true
        });

        emit PoolCreated(poolCount, _tokenA, _tokenB, _feeBasisPoints);
        return poolCount;
    }

    /**
     * @dev Add liquidity to a pool
     */
    function addLiquidity(uint256 poolId, uint256 amountA, uint256 amountB) external {
        Pool storage pool = pools[poolId];
        require(pool.exists, "Pool does not exist");

        pool.reserveA += amountA;
        pool.reserveB += amountB;

        emit LiquidityAdded(poolId, amountA, amountB);
    }

    /**
     * @dev Swap tokenA for tokenB or vice versa
     */
    function swap(uint256 poolId, address tokenIn, uint256 amountIn) external returns (uint256 amountOut) {
        Pool storage pool = pools[poolId];
        require(pool.exists, "Pool does not exist");

        bool isAToB = tokenIn == pool.tokenA;
        require(isAToB || tokenIn == pool.tokenB, "Invalid token");

        (uint256 reserveIn, uint256 reserveOut) = isAToB
            ? (pool.reserveA, pool.reserveB)
            : (pool.reserveB, pool.reserveA);

        uint256 amountInWithFee = amountIn * (10000 - pool.feeBasisPoints);
        amountOut = (amountInWithFee * reserveOut) / (reserveIn * 10000 + amountInWithFee);

        if (isAToB) {
            pool.reserveA += amountIn;
            pool.reserveB -= amountOut;
        } else {
            pool.reserveB += amountIn;
            pool.reserveA -= amountOut;
        }

        emit Swapped(poolId, tokenIn, amountIn, isAToB ? pool.tokenB : pool.tokenA, amountOut);
    }

    function getReserves(uint256 poolId) external view returns (uint256 reserveA, uint256 reserveB) {
        Pool storage pool = pools[poolId];
        return (pool.reserveA, pool.reserveB);
    }
}
