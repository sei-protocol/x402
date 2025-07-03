# X402 Documentation

This folder contains the Mintlify documentation for X402 Protocol with emphasis on Sei Network integration.

## Structure

```
docs/
├── mint.json                 # Mintlify configuration
├── introduction.mdx          # Main introduction page
├── overview.mdx              # Protocol overview
├── quickstart.mdx            # Quick start guide
├── sei/                      # Sei Network specific guides
│   ├── introduction.mdx      # Why Sei for X402
│   ├── setup.mdx             # Development environment setup
│   ├── first-payment.mdx     # First payment walkthrough
│   └── exact-payments.mdx    # Exact payment implementation
├── clients/                  # Client library documentation
├── facilitators/             # Server/facilitator guides
├── examples/                 # Full-stack examples
├── paywall/                  # Paywall system docs
└── api/                      # API reference
```

## Running Locally

To run the documentation locally:

1. Install Mintlify CLI:
   ```bash
   npm install -g mintlify
   ```

2. Start the dev server:
   ```bash
   cd docs
   mintlify dev
   ```

3. Open http://localhost:3000 to view the docs

## Deployment

This documentation is designed to be deployed with Mintlify hosting. The configuration is already set up in `mint.json`.

## Key Features

- **Sei Network Focus**: Documentation emphasizes Sei's advantages for micropayments
- **Practical Howtos**: Step-by-step guides for real implementation
- **Code Examples**: Complete, runnable code samples
- **Multiple Languages**: TypeScript/JavaScript examples throughout
- **Production Ready**: Includes deployment, monitoring, and optimization guides

## Content Guidelines

- All examples use Sei Network (testnet for development, mainnet for production)
- Include both basic and advanced implementations
- Provide troubleshooting sections for common issues
- Link to relevant Sei documentation and resources
- Use realistic payment amounts and use cases 