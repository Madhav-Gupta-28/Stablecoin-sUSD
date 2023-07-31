// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Stablecoin.sol";

/**
 * @title sUSDEngine
 * @author Madhav Gupta
 * Description =>  Main Stablecoin contract 
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 * 
 * 
 * @notice Our sUSD  system should be overcollateralized. 
 */

contract sUSDEngine is ReentrancyGuard {

    /**
     * @notice Initialiing StableCoin Contract
     */

    StableCoin private immutable i_uSUD;


       /**
     * State Variables
     */

    mapping(address token => address priceFeed) public s_priceFeeds; // token address to price feed address
    address[] public  s_collateralTokens; // keeping track of all accepted  token address of collateral 


    /**
     * Errors 
     */

    error sUSD_CollateralMorethanZero();
    error sUSD_TokenasCollateralNotAllowed();
    error LenghtOfTokenAndPriceFeedArrayNotMatches();

    /**
     * Modifiers
     */
    modifier amountMorethanZero(uint256 amount){
        if(amount <= 0){
            revert sUSD_CollateralMorethanZero();
        }
        _;
    }

       modifier isAllowedToken(address tokenAddress){
        if(s_priceFeeds[tokenAddress] == address(0)){
            revert sUSD_TokenasCollateralNotAllowed(); 
        }
        _;
    }



    /**
     * Functions
     */
    // ETH To USD pricefees address - 0x694AA1769357215DE4FAC081bf1f309aDC325306
    // ETH address on sepolia - 
    constructor(address[] memory tokenAddress , address[] memory priceFeedAddress , address sUSDAddress){
        if(tokenAddress.length != priceFeedAddress.length){
            revert LenghtOfTokenAndPriceFeedArrayNotMatches();
        }
        // These feeds will be the USD pairs
        // For example ETH / USD or MKR / USD
        for (uint256 i = 0; i < tokenAddress.length; i++) {
            s_priceFeeds[tokenAddress[i]] = priceFeedAddress[i];
            s_collateralTokens.push(tokenAddress[i]);
        }
        i_uSUD = StableCoin(sUSDAddress);

    }

    function depositCollateralAndMintsUSD() external {}



    /**
     * @param tokenCollateralAddress The address of token user wants to deposit
     * @param amountOfCollateral  Amount of it
     */
    function depositCollateral(address tokenCollateralAddress , uint256 amountOfCollateral) 
    amountMorethanZero(amountOfCollateral)
    isAllowedToken(tokenCollateralAddress)
     external 
     nonReentrant
     {

        






    }


    function mintsUSD() external {}

    function redeemCollateralForsUSD() external {}

     function redeemCollateral() external {}

    function burnsUSD() external {}
    
    function liquidate() external {}

    function getHealthfactor() external {}








}

