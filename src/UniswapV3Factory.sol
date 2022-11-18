// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./interfaces/IUniswapV3PoolDeployer.sol";
import "./UniswapV3Pool.sol";

contract UniswapV3Factory is IUniswapV3PoolDeployer {
    error TokensMustBeDifferent();
    error UnsupportedTickSpacing();
    error TokenXCannotBeZero();
    error PoolAlreadyExist();

    PoolParameters public parameters;
    mapping(address => mapping(address => mapping(uint24 => address)))
        public pools;
    mapping(uint24 => bool) public tickSpacings;

    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed tickSpacing,
        address pool
    );

    constructor() {
        tickSpacings[10] = true;
        tickSpacings[60] = true;
        tickSpacings[200] = true;
    }

    function createPool(
        address tokenX,
        address tokenY,
        uint24 tickSpacing
    ) public returns (address pool) {
        if (tokenX == tokenY) revert TokensMustBeDifferent();
        if (!tickSpacings[tickSpacing]) revert UnsupportedTickSpacing();

        (tokenX, tokenY) = tokenX < tokenY
            ? (tokenX, tokenY)
            : (tokenY, tokenX);

        if (tokenX == address(0)) revert TokenXCannotBeZero();
        if (pools[tokenX][tokenY][tickSpacing] != address(0))
            revert PoolAlreadyExist();

        parameters = PoolParameters({
            factory: msg.sender,
            token0: tokenX,
            token1: tokenY,
            tickSpacing: tickSpacing
        });

        pool = address(
            new UniswapV3Pool{
                salt: keccak256(abi.encodePacked(tokenX, tokenY, tickSpacing))
            }()
        );

        delete parameters;

        pools[tokenX][tokenY][tickSpacing] = pool;
        pools[tokenY][tokenX][tickSpacing] = pool;

        emit PoolCreated(tokenX, tokenY, tickSpacing, pool);
    }
}
