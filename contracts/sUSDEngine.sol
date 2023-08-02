// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Stablecoin.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


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
    address AcceptedAsDepositTokenAddress;
    address priceFeed;
    address[] public  s_collateralTokens; // keeping track of all accepted  token address of collateral 
    mapping(address user => mapping(address collateralToken => uint256 amount)) public userToCollateralDeposited ; // amount of and token deposit by user 
    mapping(address user => uint256 amount) public userToSUSDAmount; // amount of sUSD minted by user
    uint256 private constant LIQUIDATION_THRESHOLD = 50 ; // 50% of collateral value

    /**
     * Errors 
     */

    error sUSD_CollateralMorethanZero();
    error sUSD_TokenasCollateralNotAllowed();
    error LenghtOfTokenAndPriceFeedArrayNotMatches();
    error sUSD_DepositCollateralFailed();
    error sUSD_MintingFailed();
    error HEALTH_FACTOR_IS_LESS_THAN_ONE(uint256 healthFactor);

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
     * Events
     */
    event CollateralDeposited(address indexed depositer , address token , uint256 amount );


    /**
     * Functions
     */
    // ETH To USD pricefees address - 0x694AA1769357215DE4FAC081bf1f309aDC325306
    // Network - Sepolia
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


    /**
     * @param tokenCollateralAddress The address of token user wants to deposit
     * @param amountOfCollateral Amount of it
     * @param amountToMint  Amount of sUSD to mint
     * @notice It is Simply calling other two functions and Just Acting as a wrapper
     */
    function depositCollateralAndMintsUSD(address tokenCollateralAddress , uint256 amountOfCollateral , uint256 amountToMint) external {
        depositCollateral( tokenCollateralAddress ,  amountOfCollateral);
        mintsUSD(amountToMint);
    }



    /**
     * @param tokenCollateralAddress The address of token user wants to deposit
     * @param amountOfCollateral  Amount of it
     */
    function depositCollateral(address tokenCollateralAddress , uint256 amountOfCollateral) 
    amountMorethanZero(amountOfCollateral)
    isAllowedToken(tokenCollateralAddress)
     public 
     nonReentrant
     {

    userToCollateralDeposited[msg.sender][tokenCollateralAddress] += amountOfCollateral;
    emit CollateralDeposited(msg.sender,tokenCollateralAddress ,amountOfCollateral);

    bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender , address(this), amountOfCollateral)    ;
      if(!success){
        revert sUSD_DepositCollateralFailed();
    }
    }

    /**
     * @notice Mints sUSD tokens
     * @param amountTomint Amount of sUSD to mint
     * @notice Checks the Health Factor First Before Minting the sUSD
     */
    function mintsUSD(uint256 amountTomint) public  amountMorethanZero(1) nonReentrant {

        userToSUSDAmount[msg.sender] += amountTomint;
        revertIfHealthFactorIsBad(msg.sender);
        bool minted =  i_uSUD.mint(msg.sender , amountTomint);

        if(!minted){
            revert sUSD_MintingFailed();
        }
    }

    function redeemCollateralForsUSD() external {}

     function redeemCollateral() external {}

    function burnsUSD() external {}
    
    function liquidate() external {}

    function getHealthfactor() external {}


    /////////////////////////////////////////// 
    // Private Or Internal View  Functions // 
    //////////////////////////////////////////




    /**
     * @notice Get the latest price of ETH / USD
     * @return Returns the latest value of collateral(which is in ETH) in terms of USD
     */
    function getLatestData(uint256 collateral) private   view returns (int) {
        AggregatorV3Interface datafeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
    // prettier-ignore
    (
        /* uint80 roundID */,
        int answer,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
    ) = datafeed.latestRoundData();

    // Convert the raw value to USD with 8 decimal places
    uint256 priceInUSD = (((uint256(answer) * 1e10 ) * collateral) / 1e18);

    // Round down to the nearest integer (1824)
    return int(priceInUSD);
}   

    /**
     * 
     * @param user user address
     * @param totalsUSDMinted total sUSD minted by user
     * @param collateralValue collateral value of user 
     * @return totalsUSDMinted , collateralValue 
     */
    function _getUserInfo(address user) private view returns(uint256 totalsUSDMinted , uint256 collateralValue ) {
        totalsUSDMinted = userToSUSDAmount[user];

        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = userToCollateralDeposited[user][token];
            uint256 price = uint256(getLatestData(userToCollateralDeposited[user][token]));
            collateralValue += amount * price;
        }
        return (totalsUSDMinted , collateralValue);
    }

    /**
     * @param user  user address 
     * @return Returns the health factor of user. If it is below certain level.... liquidate user 
     */
    function getHealthfactor(address user ) private  view returns(uint256) {
            (uint256 totalsUSDMinted , uint256 collateralValueInUSD) = _getUserInfo(user);
            return calculateHealthFactor(totalsUSDMinted, collateralValueInUSD);
    }

    /**
     * 
     * @param totalsUSDMinted Passing uSUD Minted as arg
     * @param collateralValueInUSD Passing Colateral Value in Usd  as arg
     */
    function calculateHealthFactor(uint256 totalsUSDMinted , uint256 collateralValueInUSD) internal pure returns(uint256) {
             if (totalsUSDMinted == 0) return type(uint256).max;
        uint256 collateralAdjustedForThreshold = (collateralValueInUSD * LIQUIDATION_THRESHOLD) / 100;
        return (collateralAdjustedForThreshold * 1e18) / totalsUSDMinted;
    }
    
    /**
     * @param user user address
     * @notice Reverts if health factor is less than 1
     */
    function revertIfHealthFactorIsBad(address user) internal view {
        uint256 healthFactor = getHealthfactor(user);
        if(healthFactor < 1){ // 1 is Minimum Health Factor
            revert HEALTH_FACTOR_IS_LESS_THAN_ONE(healthFactor);
        }
    }





}

