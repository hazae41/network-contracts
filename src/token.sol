// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

uint256 constant U256_MAX = (2 ** 256) - 1;

uint256 constant U256_1K = 10 ** 3;
uint256 constant U256_1M = 10 ** 6;

contract Network is ERC20, ERC20Burnable {

    mapping(uint256 => bool) public isClaimed;

    uint256 public totalCount = 1;
    uint256 public totalValue = 1;

    constructor()
        ERC20("Network", "NET")
    {}

    function claim(uint256 _nonce, uint256[] calldata _secrets) public {
        uint256 _minted = 0;

        uint256 _totalCount = totalCount;
        uint256 _totalValue = totalValue;

        uint256 _average = _totalValue / _totalCount;

        for (uint256 _i = 0; _i < _secrets.length; _i++) {
            uint256 _secret = _secrets[_i];

            /**
             * Zero-knowledge proof
             */
            uint256 _proof = uint256(keccak256(abi.encode(_secret)));

            /**
             * Different for each given chain + contract + receiver + nonce
             */
            uint256 _divisor = uint256(keccak256(abi.encode(block.chainid, address(this), msg.sender, _nonce, _proof)));

            if (_divisor == 0)
                continue;
            if (isClaimed[_divisor])
                continue;

            uint256 _value;

            unchecked {
                /**
                 * Rarer hashes yield more coins
                 */
                _value = U256_MAX / _divisor;

                _totalCount += 1;
                _totalValue += _value;

                if (_average < U256_1K)
                    _average = U256_1K;

                _value = _value / (_average / U256_1K);

                if (_value > U256_1M)
                    _value = U256_1M;
                
                _average = _totalValue / _totalCount;
                _minted += _value;
            }

            isClaimed[_divisor] = true;
        }

        totalValue = _totalValue;
        totalCount = _totalCount;

        _mint(msg.sender, _minted);
    }

}
