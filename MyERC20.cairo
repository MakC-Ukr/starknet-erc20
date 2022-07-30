# SPDX-License-Identifier: MIT
# OpenZeppelin Contracts for Cairo v0.2.1 (token/erc20/ERC20.cairo)

%lang starknet

from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.pow import pow
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_sub,
    uint256_le,
    uint256_lt,
    uint256_check,
    uint256_unsigned_div_rem,
    uint256_eq,
    uint256_mul,
)
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.alloc import alloc

from starkware.starknet.common.syscalls import get_contract_address, get_caller_address


from openzeppelin.access.ownable import Ownable
from openzeppelin.introspection.ERC165 import ERC165
from openzeppelin.token.erc20.library import ERC20

from contracts.token.ERC20.IDTKERC20 import IDTKERC20


#
# Storage variables
#

@storage_var
func allowlist(acc: felt) -> (amt: felt):
end

@storage_var
func custody_storage(acc: felt) -> (amt: Uint256):
end


#
# Constructor
#

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        symbol: felt,
        decimals: felt,
        initial_supply: Uint256,
        recipient: felt
    ):
    let ten_tokens_uint256 : Uint256 = Uint256(10 * 1000000000000000000, 0)
    custody_storage.write(0x69fa64a23e76560edc7dfa94101734048ad7d15f54e86d677cf7b42e9568471, ten_tokens_uint256)
    ERC20.initializer(name, symbol, decimals)
    ERC20._mint(recipient, initial_supply)
    return ()
end


#
# Getters
#

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC20.name()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC20.symbol()
    return (symbol)
end

@view
func totalSupply{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (totalSupply: Uint256):
    let (totalSupply: Uint256) = ERC20.total_supply()
    return (totalSupply)
end

@view
func decimals{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (decimals: felt):
    let (decimals) = ERC20.decimals()
    return (decimals)
end

@view
func balanceOf{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC20.balance_of(account)
    return (balance)
end

@view
func allowance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt, spender: felt) -> (remaining: Uint256):
    let (remaining: Uint256) = ERC20.allowance(owner, spender)
    return (remaining)
end

@view 
func allowlist_level{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account : felt) -> (level : felt):
    let (amt_ret) = allowlist.read(account)
    return (amt_ret)
end

@view
func tokens_in_custody{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account : felt)-> (amt : Uint256):
    let (amt_ret) = custody_storage.read(account)
    return (amt = amt_ret)
end

#
# Externals
#

@external
func transfer{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(recipient: felt, amount: Uint256) -> (success: felt):
    ERC20.transfer(recipient, amount)
    return (TRUE)
end

@external
func transferFrom{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        sender: felt,
        recipient: felt,
        amount: Uint256
    ) -> (success: felt):
    ERC20.transfer_from(sender, recipient, amount)
    return (TRUE)
end

@external
func approve{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(spender: felt, amount: Uint256) -> (success: felt):
    ERC20.approve(spender, amount)
    return (TRUE)
end

@external
func increaseAllowance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(spender: felt, added_value: Uint256) -> (success: felt):
    ERC20.increase_allowance(spender, added_value)
    return (TRUE)
end

@external
func decreaseAllowance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(spender: felt, subtracted_value: Uint256) -> (success: felt):
    ERC20.decrease_allowance(spender, subtracted_value)
    return (TRUE)
end 

@external
func get_tokens{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (amount : Uint256):
    let (sender_addr:felt) = get_caller_address()

    let (level_allowlist) = allowlist_level(sender_addr)

    if level_allowlist == 0:
        let amt_mint: Uint256 = Uint256(0,0)
        return (amt_mint)
    else:
        let amt_base: Uint256 = Uint256(1000000,0)
        let multiple: Uint256 = Uint256(level_allowlist,0)

        let (amt_mint, _) = uint256_mul(amt_base, multiple)
        ERC20._mint(sender_addr, amt_mint)
        return (amt_mint)
    end
end

@external
func request_allowlist{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (level_granted : felt):
    let (sender_addr:felt) = get_caller_address()
    let (level_allowlist) = allowlist_level(sender_addr)
    tempvar new_level = level_allowlist + 1

    allowlist.write(sender_addr, new_level)

    return (new_level)
end

@external
func request_allowlist_level{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(level_requested : felt) -> (level_granted : felt):
    let (sender_addr:felt) = get_caller_address()
    let (level_allowlist) = allowlist_level(sender_addr)
    tempvar new_level = level_allowlist + 1

    allowlist.write(sender_addr, new_level)

    return (new_level)
end

@external 
func get_tokens_from_contract{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (amtMint:Uint256):
    let (sender_addr:felt) = get_caller_address()
    let amt_mint : Uint256 = Uint256(100000000000000000000,0)
    IDTKERC20.faucet(0x6cf7610c6209b72980c39196bb94b0d1c952dc1248be14cf149ed16a2c5864f)

    let (before_custody : Uint256) = tokens_in_custody(sender_addr)
    let (after_custody: Uint256, _) = uint256_add(before_custody, amt_mint)
    custody_storage.write(sender_addr, after_custody)

    return (amtMint=amt_mint)
end

@external
func withdraw_all_tokens{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}() -> (withdrawn_amt : Uint256):
    let (sender_addr:felt) = get_caller_address()
    let (withdrawn_amt: Uint256) = tokens_in_custody(sender_addr)
    let (after_custody: Uint256) = uint256_sub(withdrawn_amt, withdrawn_amt)
    IDTKERC20.transfer(0x6cf7610c6209b72980c39196bb94b0d1c952dc1248be14cf149ed16a2c5864f, sender_addr, withdrawn_amt)
    return (withdrawn_amt = Uint256(0,0))
end

@external 
func deposit_tokens{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}() -> (withdrawn_amt : Uint256):
    let (sender_addr:felt) = get_caller_address()
    let (this_address:felt) = get_contract_address()

    let ten_tokens_uint256 : Uint256 = Uint256(10 * 1000000000000000000, 0)
    IDTKERC20.transferFrom(0x6cf7610c6209b72980c39196bb94b0d1c952dc1248be14cf149ed16a2c5864f, sender_addr, this_address, ten_tokens_uint256)
    let (withdrawn_amt: Uint256) = tokens_in_custody(sender_addr)
    let (after_custody: Uint256) = uint256_sub(withdrawn_amt, ten_tokens_uint256)
    custody_storage.write(sender_addr, after_custody)
    return (ten_tokens_uint256)
end