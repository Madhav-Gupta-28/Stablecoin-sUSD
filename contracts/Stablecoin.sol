// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// imports 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



/*
 * @title StableCoin
 * @author Madhav Gupta
 * Collateral: Exogenous
 * Minting (Stability Mechanism): Decentralized (Algorithmic)
 * Value (Relative Stability): Anchored (Pegged to USD)
 * Collateral Type: Crypto
 *
 * This is the contract meant to be owned by DSCEngine. It is a ERC20 token that can be minted and burned by the DSCEngine smart contract.
 */


contract StableCoin is Ownable , ERC20Burnable {


    //Errors
    error DecentralizedStableCoin__AmountMustBeMoreThanZero();
    error DecentralizedStableCoin__BurnAmountExceedsBalance();
    error DecentralizedStableCoin__NotZeroAddress();

    // initiilizing erc20 token in constructor
    constructor() ERC20("StbaleCoin","sUSD"){}


    function burn(uint256 _amount) public override onlyOwner() {
        uint256 balance = balanceOf(msg.sender);
        if(_amount <= 0 ){
               revert DecentralizedStableCoin__AmountMustBeMoreThanZero();
        }

        if(balance < _amount){
            revert DecentralizedStableCoin__BurnAmountExceedsBalance();
        }

        super.burn(_amount);
    }

    function mint(address to , uint256 amount) external onlyOwner returns(bool){
         if (to == address(0)) {
            revert DecentralizedStableCoin__NotZeroAddress();
        }
        if (amount <= 0) {
            revert DecentralizedStableCoin__AmountMustBeMoreThanZero();
        }
        _mint(to, amount);
        return true;
    }
}


