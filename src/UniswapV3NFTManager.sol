// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/tokens/ERC721.sol";

contract UniswapV3NFTManager is ERC721 {
    struct TokenPosition {
        address pool;
        int24 lowerTick;
        int24 upperTick;
    }

    struct CollectParams {
        uint256 tokenId;
        uint128 amount0;
        uint128 amount1;
    }

    struct MintParams {
        address recipient;
        address tokenA;
        address tokenB;
        uint24 fee;
        int24 lowerTick;
        int24 upperTick;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    struct RemoveLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
    }

    mapping(uint256 => TokenPosition) public positions;

    address public immutable factory;

    constructor(address factoryAddress)
        ERC721("UniswapV3 NFT Positions", "UNIV3")
    {
        factory = factoryAddress;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return "";
    }

    function mint(MintParams calldata params) public returns (uint256 tokenId) {
        IUniswapV3Pool pool = getPool(params.tokenA, params.tokenB, params.fee);

        (uint128 liquidity, uint256 amount0, uint256 amount1) = _addLiquidity(
            AddLiquidityInternalParams({
                pool: pool,
                lowerTick: params.lowerTick,
                upperTick: params.upperTick,
                amount0Desired: params.amount0Desired,
                amount1Desired: params.amount1Desired,
                amount0Min: params.amount0Min,
                amount1Min: params.maount1Min
            })
        );

        tokenId = nextTokenId++;
        _mint(params.recipient, tokenId);
        totalSupply++;

        TokenPosition memory tokenPosition = TokenPosition({
            pool: address(pool),
            lowerTick: params.lowerTick,
            upperTick: params.upperTick
        });

        positions[tokenId] = tokenPosition;
    }

    function addLiquidity(AddLiquidityParams calldata params)
        public
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        TokenPosition memory tokenPosition = positions[params.tokenId];
        if (tokenPosition.pool == address(0)) revert WrongToken();

        (liquidity, amount0, amount1) = _addLiquidity(
            AddLiquidityInternalParams({
                pool: IUniswapV3Pool(tokenPosition.pool),
                lowerTick: tokenPosition.lowerTick,
                upperTick: tokenPosition.upperTick,
                amount0Desired: params.amount0Desired,
                amount1Desired: params.amount1Desired,
                amount0Min: params.amount0Min,
                amount1Min: params.maount1Min
            })
        );
    }

    function removeLiquidity(RemoveLiquidityParams memory params)
        public
        isApprovedOrOwner(params.tokenId)
        returns (uint256 amount0, uint256 amount1)
    {
        TokenPosition memory tokenPosition = positions[params.tokenId];
        if (tokenPosition.pool == address(0)) revert WrongToken();
        IUniswapV3Pool pool = IUniswapV3Pool(tokenPosition.pool);

        (uint128 availableLiquidity, , , , ) = pool.positions(
            poolPositionKey(tokenPosition)
        );

        if (params.liquidity > availableLiquidity) revert NotEnoughLiquidity();

        (amount0, amount1) = pool.burn(
            tokenPosition.lowerTick,
            tokenPosition.upperTick,
            params.liquidity
        );
    }

    function collect(CollectParams memory params)
        public
        isApprovedOrOwner(params.tokenId)
        returns (uint128 amount0, uint128 amount1)
    {
        TokenPosition memory tokenPosition = positions[params.tokenId];
        if (tokenPosition.pool == address(0)) revert WrongToken();
        IUniswapV3Pool pool = IUniswapV3Pool(tokenPosition.pool);

        (amount0, amount1) = pool.collect(
            msg.sender,
            tokenPosition.lowerTick,
            tokenPosition.upperTick,
            params.amount0,
            params.amount1
        );
    }

    function burn(uint256 tokenId) public isApprovedOrOwner(tokenId) {
        TokenPosition memory tokenPosition = positions[tokenId];
        if (tokenPosition.pool == address(0)) revert WrongToken();
        IUniswapV3Pool pool = IUniswapV3Pool(tokenPosition.pool);

        (uint128 liquidity, , , uint128 tokensOwed0, uint128 tokensOwed1) = pool
            .positions(poolPositionKey(tokenPosition));

        if (liquidity > 0 || tokensOwed0 > 0 || tokensOwed1 > 0)
            revert PositionNotCleared();

        delete positions[tokenId];
        _burn(tokenId);
        totalSupply--;
    }
}
