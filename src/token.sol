// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

uint256 constant U256_MAX = (2 ** 256) - 1;

contract Network is ERC20, ERC20Burnable {

    mapping(uint256 => bool) public isClaimed;

    uint256 public totalCount = 1;    
    uint256 public totalValue = 1;

    constructor()
        ERC20("Network", "NET")
    {}

    function claim(uint256[] calldata _secrets) public {
        uint256 _minted = 0;
        
        uint256 _totalCount = totalCount;
        uint256 _totalValue = totalValue;

        uint256 _totalAverage = _totalValue / _totalCount;

        for (uint256 _i = 0; _i < _secrets.length; _i++) {
            uint256 _secret = _secrets[_i];

            if (isClaimed[_secret])
                continue;

            /**
             * Zero-knowledge proof
             */
            uint256 _proof = uint256(keccak256(abi.encode(_secret)));

            /**
             * Value is different for each given chain + contract + receiver
             */
            uint256 _divisor = uint256(keccak256(abi.encode(block.chainid, address(this), msg.sender, _proof)));

            if (_divisor == 0)
                continue;

            uint256 _value;

            unchecked {
               /**
                * Rarer hashes yield more coins
                */
                _value = U256_MAX / _divisor;

                /**
                 * Take the raw value into account
                 */
                _totalCount += 1;
                _totalValue += _value;
                _totalAverage = _totalValue / _totalCount;

                /**
                 * Halving based on average
                 */
                _value = _value / _totalAverage;

                /**
                 * Nerf if lucky value is too far from the current average
                 */
                if (_value > 1000)
                    _value = 1000;

                _minted += _value;
            }

            isClaimed[_secret] = true;
        }

        totalCount = _totalCount;
        totalValue = _totalValue;

        _mint(msg.sender, _minted);
    }

}
