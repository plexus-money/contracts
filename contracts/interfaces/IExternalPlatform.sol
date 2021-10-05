// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IExternalPlatform {
    function getAPR(address _farmAddress, address _tokenAddress)
        external
        view
        returns (uint256 apy);

    function getStakedPoolBalanceByUser(address _owner, address tokenAddress)
        external
        view
        returns (uint256);

    function depositBalances(address userAddress, address tokenAddress)
        external
        view
        returns (uint256);

    function totalAmountStaked(address tokenAddress)
        external
        view
        returns (uint256);
        
    function commission() external view returns (uint256);
}
