# ArcPay Agent

An on-chain USDC payment and treasury rebalancing agent built for **Arc Testnet**.

ArcPay Agent enables an owner-controlled smart contract to execute USDC payments and automatically rebalance funds when a configurable balance threshold is reached.

## ✨ Features

- 💸 On-chain USDC payments
- 🔄 Threshold-based automatic rebalancing
- 🛡️ Owner-only payment and rebalance execution
- 📡 On-chain payment and rule events
- 🔐 Ownership transfer
- 🧪 11 automated Foundry tests
- ✅ Verified on Arc Testnet

## 🏗️ Architecture

```text
                    Arc Testnet
                         │
                         ▼
                 ┌─────────────────┐
                 │   ArcPayAgent   │
                 │                 │
                 │   USDC balance  │
                 └────────┬────────┘
                          │
             ┌────────────┴────────────┐
             ▼                         ▼
      executePayment()        checkAndRebalance()
             │                         │
             ▼                         ▼
        USDC transfer            Threshold check
                                       │
                                  threshold reached
                                       │
                                       ▼
                                  USDC transfer
```

## 🔗 Deployment

**Network:** Arc Testnet

**Contract:**

`0xB76eaE02179E1bA61809150628016471aB02D1eA`

**USDC:**

`0x3600000000000000000000000000000000000000`

**Contract verification:**

https://testnet.arcscan.app/address/0xb76eae02179e1ba61809150628016471ab02d1ea

## 💳 Live Demo

The contract has been deployed and tested on Arc Testnet.

### Initial Deposit

1,000,000 USDC base units were transferred to the agent.

**Transaction:**

`0xd8309deef3be56b2ad588f91c016d304718e5f377afa3fc7e53fd152f81d96b2`

### Manual Payment

100,000 USDC base units were sent using:

```solidity
executePayment(
    recipient,
    100000,
    "Test payment"
)
```

**Transaction:**

`0x05dfbe09b0670ac045c7fa807f6e00eb38297dc89e45be061f6217ed8452ea96`

### Automatic Rebalance

The agent was configured with:

- Threshold: `500,000`
- Rebalance amount: `100,000`

The rule triggered successfully and emitted:

```text
RuleTriggered("rebalance", 100000)
PaymentExecuted(..., 100000, "Auto rebalance")
```

**Transaction:**

`0x93f68dc4c92eae3b8cd552165bb9c6331532fcb90d8eed074ed4b9206ed1f338`

## 🧪 Testing

ArcPay Agent includes automated Foundry tests covering:

- Owner initialization
- USDC configuration
- Initial balance
- Manual payments
- Payment events
- Rebalance execution
- Rebalance events
- Threshold protection
- Owner authorization
- Ownership transfer

### Test Result

```text
11 tests passed
0 failed
0 skipped
```

Run the test suite:

```bash
forge test -vv
```

Format the project:

```bash
forge fmt
```

Build:

```bash
forge build
```

## 📂 Project Structure

```text
arcpay-agent/
├── src/
│   └── ArcPayAgent.sol
├── test/
│   └── ArcPayAgent.t.sol
├── script/
│   └── DeployArcPayAgent.s.sol
├── broadcast/
├── foundry.toml
├── foundry.lock
├── constructor.args
└── README.md
```

## ⚙️ Core Contract

### `executePayment()`

Allows the owner to execute a USDC payment from the agent balance.

```solidity
function executePayment(
    address to,
    uint256 amount,
    string calldata reason
) external onlyOwner
```

### `checkAndRebalance()`

Checks the agent's USDC balance against a threshold and executes a transfer when the threshold is reached.

```solidity
function checkAndRebalance(
    address target,
    uint256 threshold,
    uint256 sendAmount
) external onlyOwner
```

### Events

```solidity
event PaymentExecuted(
    address indexed to,
    uint256 amount,
    string reason
);

event RuleTriggered(
    string ruleName,
    uint256 amount
);

event Deposit(
    address indexed from,
    uint256 amount
);
```

## 🚀 Deployment

The contract can be deployed using Foundry:

```bash
forge script script/DeployArcPayAgent.s.sol \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast
```

The USDC address is configured in:

```text
script/DeployArcPayAgent.s.sol
```

## 🔒 Security

The contract uses owner-based authorization for payment and rebalance operations.

The `.env` file containing private deployment credentials is excluded from version control.

## 📜 License

MIT
