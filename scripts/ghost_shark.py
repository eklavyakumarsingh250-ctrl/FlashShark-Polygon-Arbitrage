import time
import json
from web3 import Web3

# CONFIGURATION
RPC_URL = "https://polygon-rpc.com"
web3 = Web3(Web3.HTTPProvider(RPC_URL))

# ROUTERS & TOKENS
QUICK_ROUTER = "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff"
SUSHI_ROUTER = "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506"
WMATIC = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"
USDC   = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
WETH   = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"

router_abi = '[{"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"}],"name":"getAmountsOut","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"view","type":"function"}]'

quick_contract = web3.eth.contract(address=QUICK_ROUTER, abi=json.loads(router_abi))
sushi_contract = web3.eth.contract(address=SUSHI_ROUTER, abi=json.loads(router_abi))

print("🦈 GHOST SHARK: ONLINE")

while True:
    try:
        # Check MATIC -> USDC
        amount_in = web3.to_wei(100, 'ether')
        path = [WMATIC, USDC]
        q_price = quick_contract.functions.getAmountsOut(amount_in, path).call()[1] / 1000000
        s_price = sushi_contract.functions.getAmountsOut(amount_in, path).call()[1] / 1000000
        diff = s_price - q_price

        if abs(diff) > 0.2:
            print(f"🚨 GAP FOUND: ${diff:.2f} | Quick: {q_price} Sushi: {s_price}")
        else:
            print(f"Scanning... Gap: ${diff:.4f}", end='\r')
            
    except Exception as e:
        pass
    time.sleep(3)
