Secure, automated tin export transactions with escrow payments and shipment verification

## 📝 Overview

The Tin Export Smart Contract System eliminates fraud risks and payment delays in international tin trade through blockchain-based escrow and automated shipment verification.

## ✨ Key Features

- 🔒 **Payment Escrow** - Secure fund holding until shipment completion
- 🚛 **Automated Release** - Smart payment release on shipping oracle verification  
- 📋 **On-chain Documentation** - Immutable customs document storage
- 🛡️ **Fraud Protection** - Multi-party verification system
- ⚡ **Instant Settlement** - Automatic payment processing

## 🏗️ Contract Architecture

### Core Components
- **Export Contracts** - Main contract logic and state management
- **Customs Documents** - Secure document hash storage
- **Shipping Oracle** - Third-party delivery verification
- **User Management** - Contract tracking per user

### Contract Statuses
1. `created` - Contract initialized
2. `funded` - Payment escrowed by importer
3. `documented` - Customs documents uploaded
4. `cleared` - Customs verification completed
5. `shipped` - Goods dispatched by exporter
6. `delivered` - Shipment verified by oracle
7. `completed` - Payment released to exporter
8. `refunded` - Emergency refund processed

## 🚀 Usage Instructions

### For Exporters

1. **Create Contract**
   ```clarity
   (contract-call? .tin-export-system create-export-contract 
     'ST1IMPORTER-ADDRESS 
     u1000    ;; tin quantity in tons
     u50000)  ;; price per ton in microSTX
   ```

2. **Upload Customs Documents**
   ```clarity
   (contract-call? .tin-export-system upload-customs-document
     u1                    ;; contract-id
     0x1234...             ;; document hash
     "export-permit")      ;; document type
   ```

3. **Confirm Shipment**
   ```clarity
   (contract-call? .tin-export-system confirm-shipment u1)
   ```

### For Importers

1. **Deposit Payment**
   ```clarity
   (contract-call? .tin-export-system deposit-payment u1)
   ```

### For Contract Owner

1. **Set Shipping Oracle**
   ```clarity
   (contract-call? .tin-export-system set-shipping-oracle 'ST1ORACLE-ADDRESS)
   ```

2. **Verify Customs Clearance**
   ```clarity
   (contract-call? .tin-export-system verify-customs-clearance u1)
   ```

3. **Emergency Refund** (if needed)
   ```clarity
   (contract-call? .tin-export-system emergency-refund u1)
   ```

### For Shipping Oracle

1. **Verify Delivery**
   ```clarity
   (contract-call? .tin-export-system verify-shipment-delivery u1)
   ```

### Payment Release

Payment is automatically released when:
- Contract status is `delivered`
- Shipping oracle has verified delivery
- Payment hasn't been released yet

```clarity
(contract-call? .tin-export-system release-payment u1)
```

## 📖 Read-Only Functions

### Get Contract Details
```clarity
(contract-call? .tin-export-system get-contract u1)
```

### Get User Contracts
```clarity
(contract-call? .tin-export-system get-user-contracts 'ST1USER-ADDRESS)
```

### Get Customs Document
```clarity
(contract-call? .tin-export-system get-customs-document u1)
```

## ⚠️ Error Codes

| Code | Description |
|------|-------------|
| u100 | Owner only function |
| u101 | Contract not found |
| u102 | Unauthorized access |
| u103 | Invalid amount |
| u104 | Already exists |
| u105 | Invalid status |
| u106 | Insufficient payment |
| u107 | Shipment not verified |
| u108 | Contract completed |
| u109 | Invalid oracle |

## 🛠️ Development Setup

1. **Install Clarinet**
   ```bash
   npm install -g @hirosystems/clarinet-cli
   ```

2. **Check Contract**
   ```bash
   clarinet check
   ```

3. **Run Tests**
   ```bash
   npm install
   npm test
   ```

4. **Deploy**
   ```bash
   clarinet deploy --testnet
   ```

## 🔐 Security Features

- ✅ Owner-only administrative functions
- ✅ Status-based state transitions
- ✅ Multi-party verification requirements
- ✅ Escrow fund protection
- ✅ Oracle-based delivery confirmation
- ✅ Emergency refund capability

## 🎯 Production Considerations

- Configure trusted shipping oracle address
- Implement comprehensive testing
- Set appropriate gas limits
- Monitor contract events
- Establish oracle SLA requirements

## 📞 Support

For technical support or questions, please refer to the [Clarity documentation](https://docs.stacks.co/clarity) or open an issue in this repository.

---

**Built with ❤️ using Clarity Smart Contracts on Stacks Blockchain**

## 🚨 Dispute Resolution

The contract now includes a dispute resolution mechanism to handle conflicts between exporters and importers.

### Raising a Dispute

Either the exporter or importer can raise a dispute on an active contract:

```clarity
(contract-call? .tin-export-system raise-dispute
  u1                                      ;; contract-id
  "Quality issues with delivered tin")   ;; reason (up to 100 chars)
```

### Resolving a Dispute

The contract owner can resolve disputes with one of three outcomes:

```clarity
;; Release payment to exporter
(contract-call? .tin-export-system resolve-dispute u1 "release")

;; Refund importer
(contract-call? .tin-export-system resolve-dispute u1 "refund")

;; Cancel contract
(contract-call? .tin-export-system resolve-dispute u1 "cancel")
```

### Dispute Data Structure

Disputes store:
- **Raised by**: Principal who initiated the dispute
- **Reason**: Description of the dispute (100 chars max)
- **Timestamp**: Block height when raised
- **Resolved**: Boolean status
- **Resolution**: Optional outcome ("release", "refund", or "cancel")

### Get Dispute Details

```clarity
(contract-call? .tin-export-system get-dispute u1)
```

## 📊 Updated Contract Statuses

1. `created` - Contract initialized
2. `funded` - Payment escrowed by importer
3. `documented` - Customs documents uploaded
4. `cleared` - Customs verification completed
5. `shipped` - Goods dispatched by exporter
6. `delivered` - Shipment verified by oracle
7. `completed` - Payment released to exporter
8. `refunded` - Emergency refund processed
9. `canceled` - Contract terminated via dispute resolution

## ⚠️ Updated Error Codes

| Code | Description |
|------|-------------|
| u100 | Owner only function |
| u101 | Contract not found |
| u102 | Unauthorized access |
| u103 | Invalid amount |
| u104 | Already exists |
| u105 | Invalid status |
| u106 | Insufficient payment |
| u107 | Shipment not verified |
| u108 | Contract completed |
| u109 | Invalid oracle |
| u110 | Dispute already raised |
| u111 | No dispute found |
| u112 | Dispute not resolved |

## ✨ Enhanced Key Features

- 🔒 **Payment Escrow** - Secure fund holding until shipment completion
- 🚛 **Automated Release** - Smart payment release on shipping oracle verification
- 📋 **On-chain Documentation** - Immutable customs document storage
- 🛡️ **Fraud Protection** - Multi-party verification system
- ⚡ **Instant Settlement** - Automatic payment processing
- 🚨 **Dispute Resolution** - Structured conflict handling with owner arbitration

## 🛡️ Enhanced Security Features

- ✅ Owner-only administrative functions
- ✅ Status-based state transitions
- ✅ Multi-party verification requirements
- ✅ Escrow fund protection
- ✅ Oracle-based delivery confirmation
- ✅ Emergency refund capability
- ✅ Dispute resolution with frozen operations during active disputes
