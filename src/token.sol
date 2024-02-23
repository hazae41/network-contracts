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
        /**
         * Total value to mint
         */
        uint256 _minted = 0;

        /**
         * Load global state
         */
        uint256 _totalCount = totalCount;
        uint256 _totalValue = totalValue;

        /**
         * Compute average for the first iteration
         */
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

            /**
             * Cannot divide by 0
             */
            if (_divisor == 0)
                continue;

            /**
             * A secret can be replayed if its value differs
             */
            if (isClaimed[_divisor])
                continue;

            uint256 _value;

            unchecked {
                /**
                 * Rarer hashes yield more coins
                 */
                _value = U256_MAX / _divisor;

                /**
                 * Apply derivatives
                 */
                _totalCount += 1;
                _totalValue += _value;

                /**
                 * Minimum is 1000x lower than average
                 */
                if (_average < U256_1K)
                    _average = U256_1K;

                /**
                 * Emit at a constant rate
                 */
                _value = _value / (_average / U256_1K);

                /**
                 * Maximum is 1000x bigger than average
                 */
                if (_value > U256_1M)
                    _value = U256_1M;
                
                /**
                 * Update average after each iteration
                 */
                _average = _totalValue / _totalCount;

                /**
                 * Update total value to mint
                 */
                _minted += _value;
            }

            /**
             * Prevent replay
             */
            isClaimed[_divisor] = true;
        }

        /**
         * Save global state
         */
        totalValue = _totalValue;
        totalCount = _totalCount;

        /**
         * Only do one mint per claim
         */
        _mint(msg.sender, _minted);
    }

}
