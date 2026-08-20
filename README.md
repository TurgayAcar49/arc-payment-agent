# ArcPay Agent

An on-chain USDC payment and treasury management agent built for **Arc Testnet**.

ArcPay Agent started as a simple owner-controlled payment contract and evolved into a rule-based payment system with threshold protection and dedicated **agent authorization**.

The latest V3 architecture separates **administrative control** from **payment execution**:

* The **owner** manages payment rules and authorization.
* The authorized **agent** can execute eligible payment rules.
* Rules are protected by configurable balance thresholds.
* Deactivated rules cannot be executed.
* Agent authorization changes are tracked through on-chain events.

This makes ArcPay Agent a small but practical example of how an automated agent can interact with an on-chain payment layer while keeping administrative permissions under explicit owner control.

---

## ✨ Features

### V1 — Payment & Treasury Control

* 💸 On-chain USDC payments
* 🔄 Threshold-based treasury rebalancing
* 🛡️ Owner-only execution
* 📡 Payment and rebalance events
* 🔐 Ownership transfer

### V2 — Payment Rules

V2 introduced reusable payment rules instead of requiring every payment to be configured manually.

* 📋 Create configurable payment rules
* 🎯 Define a target recipient
* 💰 Define a payment amount
* 📊 Define a balance threshold
* ⛔ Deactivate rules
* 🛡️ Owner-only rule management
* 📡 Rule creation, execution and deactivation events
* 🔒 Prevent execution when the threshold is not reached
* 🔒 Prevent execution of inactive rules

### V3 — Agent Authorization

V3 introduces a dedicated execution agent.

* 🤖 Assign an authorized `agent`
* ⚡ Authorized agent can execute eligible rules
* 👑 Owner retains administrative control
* 🔒 Agent cannot create rules
* 🔒 Agent cannot deactivate rules
* 🔒 Agent cannot change the authorized agent
* 🔒 Unauthorized addresses cannot execute rules
* 🔒 Agent cannot execute rules below the configured threshold
* 🔒 Deactivated rules cannot be executed by the agent
* 📡 `AgentUpdated` event tracks authorization changes
* 🔁 Agent can execute multiple eligible rules

---

## 🧠 Why ArcPay Agent?

Agentic applications need more than an AI or automation layer.

They also need a **controlled on-chain execution layer**.

ArcPay Agent explores this model by separating:

```text
Decision / Automation
        │
        ▼
   Authorized Agent
        │
        ▼
    ArcPay Agent
        │
        ├── Rule validation
        ├── Threshold validation
        ├── Authorization check
        └── USDC transfer
                │
                ▼
             Recipient
```

The contract does not give the agent unrestricted control.

Instead, the owner defines the rules and authorizes a specific execution address. The agent can then execute only rules that satisfy the contract's conditions.

This creates a simple permission boundary between:

**who defines the rules** and **who executes them**.

---

# 🏗️ Architecture

```text
                         Arc Testnet
                              │
                              ▼
                    ┌──────────────────┐
                    │   ArcPay Agent   │
                    │                  │
                    │    USDC Balance  │
                    └────────┬─────────┘
                             │
                 ┌───────────┴───────────┐
                 │                       │
                 ▼                       ▼
              Owner                  Agent
                 │                       │
        ┌────────┴────────┐              │
        │                 │              │
   createRule()     deactivateRule()     │
        │                                │
        └──────────────┬─────────────────┘
                       ▼
                  executeRule()
                       │
              ┌────────┴────────┐
              │                 │
       Authorization       Threshold
           check              check
              │                 │
              └────────┬────────┘
                       ▼
                 USDC transfer
                       │
                       ▼
                   Recipient
```

---

# 🔐 Owner vs Agent Authorization

One of the main changes introduced in V3 is the separation between **administrative permissions** and **execution permissions**.

| Action                  | Owner | Agent |
| ----------------------- | :---: | :---: |
| Create rule             |   ✅   |   ❌   |
| Deactivate rule         |   ✅   |   ❌   |
| Set agent               |   ✅   |   ❌   |
| Execute eligible rule   |   ✅   |   ✅   |
| Execute below threshold |   ❌   |   ❌   |
| Execute inactive rule   |   ❌   |   ❌   |
| Change ownership        |   ✅   |   ❌   |

The agent is therefore an **execution authority**, not an administrative authority.

The owner can replace the authorized agent at any time through:

```solidity
function setAgent(address _agent) external onlyOwner
```

Every authorization change emits:

```solidity
event AgentUpdated(
    address indexed oldAgent,
    address indexed newAgent
);
```

---

# 📋 Payment Rules

A payment rule contains:

```text
target
threshold
amount
active
```

A rule can be created by the owner:

```solidity
function createRule(
    address target,
    uint256 threshold,
    uint256 amount
) external onlyOwner
```

The rule can later be executed by either the owner or the authorized agent:

```solidity
function executeRule(uint256 ruleId) external
```

Before execution, the contract validates the rule's authorization and state.

The payment is executed only when:

```text
rule.active == true
```

and:

```text
USDC balance >= rule.threshold
```

This prevents a rule from executing when the configured treasury condition has not been reached.

---

# ⚡ Agent Execution Flow

The V3 execution model is:

```text
1. Owner creates payment rule
          │
          ▼
2. Owner authorizes agent
          │
          ▼
3. Agent calls executeRule(ruleId)
          │
          ▼
4. Contract checks caller
          │
          ├── Owner       → allowed
          ├── Agent       → allowed
          └── Other       → rejected
          │
          ▼
5. Contract checks rule
          │
          ├── Active?     → required
          └── Threshold?  → required
          │
          ▼
6. USDC payment executed
          │
          ▼
7. RuleExecuted event emitted
```

This allows an external automation or agent system to trigger predefined payments without giving that system full administrative control over the contract.

---

# 📈 V1 → V2 → V3

## V1 — Direct Payment Control

The first version established the basic payment and treasury functionality.

```text
Owner
  │
  ├── executePayment()
  │
  └── checkAndRebalance()
```

The focus was simple and explicit owner-controlled USDC movement.

---

## V2 — Rule-Based Payments

V2 introduced reusable payment rules.

```text
Owner
  │
  ▼
createRule()
  │
  ▼
PaymentRule
  │
  ├── target
  ├── threshold
  ├── amount
  └── active
```

This transformed the contract from a simple payment executor into a configurable payment-rule system.

---

## V3 — Agent Authorization

V3 added a dedicated execution role.

```text
                 Owner
                   │
        ┌──────────┴──────────┐
        │                     │
   Rule Management       Agent Authorization
        │                     │
        └──────────┬──────────┘
                   ▼
              Payment Rule
                   │
                   ▼
            Authorized Agent
                   │
                   ▼
             executeRule()
```

The key design principle is:

> **The agent can execute predefined rules, but does not control the rules themselves.**

---

# 🧪 Testing

ArcPay Agent includes Foundry tests covering the complete V1 → V3 evolution.

### V1

Tests cover:

* Owner initialization
* USDC configuration
* Initial balance
* Manual payments
* Payment events
* Rebalance execution
* Rebalance events
* Threshold protection
* Owner authorization
* Ownership transfer

### V2

Tests cover:

* Rule creation
* Rule creation events
* Zero-address protection
* Zero-amount protection
* Zero-threshold protection
* Rule ID increments
* Rule execution
* Rule execution events
* Threshold protection
* Rule deactivation
* Deactivation events
* Inactive rule protection
* Owner authorization

### V3

Tests cover:

* Initial agent state
* Agent assignment
* `AgentUpdated` event
* Zero-address agent protection
* Owner-only agent management
* Authorized agent execution
* Unauthorized execution rejection
* Agent execution below threshold
* Agent execution of inactive rules
* Agent restrictions on rule management
* Multiple agent executions
* Ownership transfer

### Test Result

```text
4 test suites
58 tests passed
0 failed
0 skipped
```

Run the complete test suite:

```bash
forge test -vv
```

Format the project:

```bash
forge fmt
```

Check formatting:

```bash
forge fmt --check
```

Build:

```bash
forge build
```

---

# 📡 Events

The contract exposes events for important state changes and payment activity.

### Payment

```solidity
event PaymentExecuted(
    address indexed to,
    uint256 amount,
    string reason
);
```

### Rule Creation

```solidity
event RuleCreated(
    uint256 indexed ruleId,
    address indexed target,
    uint256 threshold,
    uint256 amount
);
```

### Rule Execution

```solidity
event RuleExecuted(
    uint256 indexed ruleId,
    address indexed target,
    uint256 amount
);
```

### Rule Deactivation

```solidity
event RuleDeactivated(uint256 indexed ruleId);
```

### Agent Authorization

```solidity
event AgentUpdated(
    address indexed oldAgent,
    address indexed newAgent
);
```

These events provide an on-chain audit trail for payment execution, rule management and agent authorization changes.

---

# 🔗 Deployment

**Network:** Arc Testnet

**Contract:**

```text
0xB76eaE02179E1bA61809150628016471aB02D1eA
```

**USDC:**

```text
0x3600000000000000000000000000000000000000
```

**Contract verification:**

https://testnet.arcscan.app/address/0xb76eae02179e1ba61809150628016471ab02d1ea

---

# 💳 Live Demo

The original ArcPay Agent deployment was deployed and tested on Arc Testnet.

## Initial Deposit

1,000,000 USDC base units were transferred to the agent.

**Transaction:**

```text
0xd8309deef3be56b2ad588f91c016d304718e5f377afa3fc7e53fd152f81d96b2
```

## Manual Payment

100,000 USDC base units were sent using:

```solidity
executePayment(
    recipient,
    100000,
    "Test payment"
)
```

**Transaction:**

```text
0x05dfbe09b0670ac045c7fa807f6e00eb38297dc89e45be061f6217ed8452ea96
```

## Automatic Rebalance

The original deployment was configured with:

```text
Threshold:        500,000
Rebalance amount: 100,000
```

The rule triggered successfully and emitted payment-related events.

**Transaction:**

```text
0x93f68dc4c92eae3b8cd552165bb9c6331532fcb90d8eed074ed4b9206ed1f338
```

> Note: The deployment above demonstrates the original payment/rebalancing flow. V2 and V3 extend the architecture with reusable payment rules and dedicated agent authorization.

---

# 📂 Project Structure

```text
arc-payment-agent/
├── .github/
│   └── workflows/
│       └── test.yml
├── src/
│   ├── ArcPayAgent.sol
│   ├── ArcPayAgentV1.sol
│   ├── ArcPayAgentV2.sol
│   └── ArcPayAgentV3.sol
├── test/
│   ├── ArcPayAgent.t.sol
│   ├── ArcPayAgentV1.t.sol
│   ├── ArcPayAgentV2.t.sol
│   └── ArcPayAgentV3.t.sol
├── script/
│   └── DeployArcPayAgent.s.sol
├── foundry.toml
├── foundry.lock
├── constructor.args
└── README.md
```

---

# 🚀 Deployment

The contract can be deployed using Foundry:

```bash
forge script script/DeployArcPayAgent.s.sol \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast
```

Deployment credentials should be supplied through environment variables and must never be committed to the repository.

---

# 🔒 Security & Authorization

ArcPay Agent uses explicit permission boundaries.

### Owner

The owner controls:

* Payment rule creation
* Rule deactivation
* Agent authorization
* Ownership transfer
* Direct execution

### Agent

The authorized agent can:

* Execute eligible payment rules

The agent cannot:

* Create payment rules
* Deactivate payment rules
* Change the authorized agent
* Execute inactive rules
* Execute rules below their configured threshold

An unauthorized address cannot execute rules.

The `.env` file containing private deployment credentials is excluded from version control.

---

# 🛠️ Development

Clone the repository and install dependencies:

```bash
git clone https://github.com/TurgayAcar49/arc-payment-agent.git
cd arc-payment-agent
```

Run tests:

```bash
forge test -vv
```

Check formatting:

```bash
forge fmt --check
```

Build:

```bash
forge build
```

---

# 🎯 Project Goal

ArcPay Agent is an experimental implementation of an **agent-controlled payment execution layer** for Arc.

The project explores a practical question:

> How can an automated agent execute on-chain payments without receiving unrestricted administrative control?

The V3 implementation answers this with a simple permission model:

```text
Owner
 │
 ├── defines rules
 ├── controls authorization
 │
 ▼
Authorized Agent
 │
 └── executes eligible rules
          │
          ▼
       USDC Payment
```

This separation provides a foundation for connecting future automation, AI agents or scheduled execution systems to an on-chain payment contract while keeping rule configuration and authorization under explicit control.

---

# 📜 License

MIT
