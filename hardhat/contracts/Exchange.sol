// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {

    // exchange is inheriting ERC20 , because our exchange itself is an ERC20 contract
    // and it will be rensposible for minting and issuing tokens

    address public tokenAddress;

    // the constructor takes the contract address of the token and saves it . 
    // the exchange will then further behave as an exchange for    ETH <> Token

    constructor(address token) ERC20("ETH TOKEN LP Token", "lpETHTOKEN") {
        require(token != address(0), "Token address passed is a null address");
        tokenAddress = token;
    }
    
    // now, let's create a simple view function that returns the balance of Token for the exchange contract ifself i.e how many tokens are i the exchange contract

    // getReserve returns the balance of 'token' held by `this` contract

    function getReserve() public view returns (uint256) {
        return ERC20(tokenAddress).balanceOf(address(this));
    }

    // a function that adds liquidity to the exchange contract

    function addLiquidity(uint256 amountOfToken) public payable returns (uint256) {
        uint256 lpTokenstToMint;
        uint256 ethReserveBalance = address(this).balance;
        uint256 tokenReserveBalance = getReserve();

        ERC20 token = ERC20(tokenAddress);

        // if the reserve is empty , take any user supplied value for initial liquidity

        if (tokenReserveBalance == 0) {
            // transfer token from the user to the exchange
            lpTokenstToMint = ethReserveBalance;

            // mint LP tokens to the user 

            _mint(msg.sender, lpTokenstToMint); // msg.sender is the user who minted the tokens
             
            return lpTokenstToMint;

        }

        // if the reserve is not empty , calculate the amount of LP Tokens to be minted 

        uint256 ethReservePriorToFunctionCall = ethReserveBalance - msg.value;
        uint256 minTokenAmountRequired = (msg.value * tokenReserveBalance ) / ethReservePriorToFunctionCall; // this code is to calculate the amount of tokens to be minted

        require(amountOfToken >= minTokenAmountRequired, "Not enough tokens to mint or not enough amount of tokens to be minted");

        // transfer the amount of tokens from the user to the Exchange

        token.transferFrom(msg.sender, address(this), minTokenAmountRequired); // msg.sender is the user who minted the tokens
        
        // calculate the amount of LP tokens to be minted

        lpTokenstToMint = (totalSupply()* msg.value) / ethReservePriorToFunctionCall;

        // mint LP tokens to the user

        _mint(msg.sender, lpTokenstToMint); // msg.sender is the user who minted the tokens


        return lpTokenstToMint; // return the amount of LP tokens to be minted
    }


    // now we need to add removeLiquidity function
    
    // removeLiquidity allows users to remove liquidity to the exchange


    function removeLiquidity(uint256 amountOfLPTokens) public returns (uint256 , uint256) {
        // check that the user want to remove > 0 LP tokens
        require(amountOfLPTokens > 0, "The amount of the tokens to be removed must be greater that 0");

        uint256 ethReservereBalance = address(this).balance; // this is the balance of the ETH token in the exchange contract
        uint256 lpTokenTotalSupply = totalSupply();

        // calculate the amount of ETH  and tokens to return to user 
        uint256 ethToReturn = (ethReservereBalance * amountOfLPTokens) / lpTokenTotalSupply;
        uint256 tokenToReturn = (getReserve() * amountOfLPTokens) / lpTokenTotalSupply;

        //  Burn the LP tokens from the user, and transfer the ETH and tokens to the user
        _burn(msg.sender, amountOfLPTokens);
        payable(msg.sender).transfer(ethToReturn);
        ERC20(tokenAddress).transfer(msg.sender, tokenToReturn);
        return (ethToReturn, tokenToReturn);
    }


        // now lets create a pure function that can perform some calculations

        // getOutputAmountFromSwap calculates the amount of output tokens to be received based on xy = (x + dx)(y - dy)

        function getOutputAmountFromSwap(
            uint256 inputAmount,
            uint256 inputReserve,
            uint256 outputReserve
        ) 
        public pure returns (uint256) {
            require(inputReserve > 0 && outputReserve > 0, "Input reserve must be greater than 0");  // the reserve must be greater than 0

            uint256 inputAmountWithFee = inputAmount * 99;
            uint256 numerator = inputAmountWithFee * outputReserve;
            uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

            return numerator / denominator;


        }  


    // ethToTokenSwap allows users to swap ETH for tokens
function ethToTokenSwap(uint256 minTokensToReceive) public payable {
    uint256 tokenReserveBalance = getReserve();
    uint256 tokensToReceive = getOutputAmountFromSwap(
        msg.value,
        address(this).balance - msg.value,
        tokenReserveBalance
    );

    require(
        tokensToReceive >= minTokensToReceive,
        "Tokens received are less than minimum tokens expected"
    );

    ERC20(tokenAddress).transfer(msg.sender, tokensToReceive);
}

// tokenToEthSwap allows users to swap tokens for ETH
function tokenToEthSwap( // 
    uint256 tokensToSwap,
    uint256 minEthToReceive
) public {
    uint256 tokenReserveBalance = getReserve();
    uint256 ethToReceive = getOutputAmountFromSwap(
        tokensToSwap,
        tokenReserveBalance,
        address(this).balance
    );// tokenReserveBalance

    require(
        ethToReceive >= minEthToReceive,
        "ETH received is less than minimum ETH expected"
    );

    ERC20(tokenAddress).transferFrom(
        msg.sender,
        address(this),
        tokensToSwap
    );

    payable(msg.sender).transfer(ethToReceive);
}

   
}