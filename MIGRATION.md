# Migrating off `@sei-js/*` x402 packages

The `@sei-js/*` x402 packages are **deprecated and no longer maintained**. Sei is now
supported natively in the upstream [x402](https://github.com/x402-foundation/x402) SDK,
so this fork no longer has a reason to exist.

Migrate to the upstream v2 `@x402/*` packages.

## Read this first: the Sei mainnet USDC changed

This fork defaults Sei mainnet (chain 1329) to an IBC-bridged USDC that **does not
implement EIP-3009**. Since EIP-3009 `transferWithAuthorization` is what the `exact`
scheme relies on to settle, payments against that asset cannot settle.

Upstream uses native USDC, which does implement EIP-3009:

| Network | Chain | This fork (broken) | Upstream (use this) |
| --- | --- | --- | --- |
| Sei mainnet | 1329 | `0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1` | `0xe15fC38F6D8c56aF07bbCBe3BAf5708A2Bf42392` |
| Sei testnet | 1328 | `0xeAcd10aaA6f362a94823df6BBC3C536841870772` | `0x4fCF1784B31630811181f670Aea7A7bEF803eaED` |

Both upstream contracts report symbol `USDC`, EIP-712 version `2`, and 6 decimals. If you
hardcoded either fork address anywhere, replace it. If you relied on the default asset,
upgrading picks up the correct one automatically.

## Timing: dollar-string pricing on Sei needs the next release

The Sei defaults are merged upstream but are **not yet in a published npm or PyPI
release**. The newest `@x402/evm` is 2.23.0 (2026-08-18), which predates the merge.

Practically, on 2.23.0 a dollar-string price on Sei throws, because `getDefaultAsset`
has no entry to resolve:

```
Error: No default asset configured for network eip155:1329
```

Everything else about Sei works on 2.23.0. Only the money-string path is affected, since
that is the one place the default asset table is consulted. So until the next release you
have two options.

Wait for the release and keep `price: "$0.10"` as shown throughout this guide. Releases
have been roughly weekly, and the Sei entries are already on `main`.

Or migrate now and name the asset explicitly, which skips the default lookup entirely:

```typescript
"GET /protected": {
  accepts: {
    scheme: "exact",
    network: "eip155:1329",
    payTo: "0xYourAddress",
    price: {
      asset: "0xe15fC38F6D8c56aF07bbCBe3BAf5708A2Bf42392",
      amount: "100000", // atomic units, so 0.10 USDC at 6 decimals
      extra: { name: "USDC", version: "2" },
    },
  },
},
```

The `extra` block carrying `name` and `version` is required: EIP-3009 tokens need them to
build the `transferWithAuthorization` EIP-712 domain.

Go is not affected. That module has no semver tags, so the proxy serves pseudo-versions
off `main` and already includes the Sei defaults.

## Package mapping

| Deprecated | Replacement |
| --- | --- |
| `@sei-js/x402` | `@x402/core` + `@x402/evm` |
| `@sei-js/x402-fetch` | `@x402/fetch` |
| `@sei-js/x402-axios` | `@x402/axios` |
| `@sei-js/x402-express` | `@x402/express` |
| `@sei-js/x402-hono` | `@x402/hono` |
| `@sei-js/x402-next` | `@x402/next` |
| `@sei-js/coinbase-x402` | `@coinbase/x402` |

The `@sei-js/*` packages tracked x402 v1. The `@x402/*` packages are v2, so this is a
protocol upgrade rather than a rename, and the API changed. The sections below cover
every breaking change you will hit.

## Network identifiers are now CAIP-2

v1 used bare network names. v2 uses CAIP-2 identifiers everywhere a network is named.

| v1 | v2 |
| --- | --- |
| `"sei"` | `"eip155:1329"` |
| `"sei-testnet"` | `"eip155:1328"` |

v2 also accepts wildcards such as `"eip155:*"` when registering a scheme for all EVM
chains.

## Clients

### fetch

Before:

```typescript
import { createWalletClient, http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { sei } from "viem/chains";
import { wrapFetchWithPayment } from "@sei-js/x402-fetch";

const account = privateKeyToAccount("0xYourPrivateKey");
const client = createWalletClient({ account, transport: http(), chain: sei });

const fetchWithPay = wrapFetchWithPayment(fetch, client);
```

After:

```typescript
import { privateKeyToAccount } from "viem/accounts";
import { wrapFetchWithPaymentFromConfig } from "@x402/fetch";
import { ExactEvmScheme } from "@x402/evm";

const account = privateKeyToAccount("0xYourPrivateKey");

const fetchWithPay = wrapFetchWithPaymentFromConfig(fetch, {
  schemes: [{ network: "eip155:1329", client: new ExactEvmScheme(account) }],
});
```

Note that v2 takes a viem `Account` rather than a `WalletClient`, so the chain is no
longer configured on the wallet. It comes from the `network` you register.

The `maxValue` parameter is gone. Spend limits are now configured on the client instead
of being passed positionally.

### axios

Before:

```typescript
import axios from "axios";
import { withPaymentInterceptor } from "@sei-js/x402-axios";

const api = withPaymentInterceptor(axios.create(), client);
```

After:

```typescript
import axios from "axios";
import { wrapAxiosWithPaymentFromConfig } from "@x402/axios";
import { ExactEvmScheme } from "@x402/evm";

const api = wrapAxiosWithPaymentFromConfig(axios.create(), {
  schemes: [{ network: "eip155:1329", client: new ExactEvmScheme(account) }],
});
```

## Servers

v1 took `payTo` as the first argument and read `price` and `network` per route. v2 takes a
pre-built `x402ResourceServer` and moves the payment terms into an `accepts` block, which
is what lets a single route offer multiple schemes or networks.

### express

Before:

```typescript
import express from "express";
import { paymentMiddleware } from "@sei-js/x402-express";

const app = express();

app.use(
  paymentMiddleware("0xYourAddress", {
    "/protected": { price: "$0.10", network: "sei" },
  }),
);
```

After:

```typescript
import express from "express";
import { paymentMiddleware, x402ResourceServer } from "@x402/express";
import { ExactEvmScheme } from "@x402/evm/exact/server";
import { HTTPFacilitatorClient } from "@x402/core/server";

const app = express();

const facilitatorClient = new HTTPFacilitatorClient({ url: "https://x402.org/facilitator" });
const resourceServer = new x402ResourceServer(facilitatorClient).register(
  "eip155:1329",
  new ExactEvmScheme(),
);

app.use(
  paymentMiddleware(
    {
      "GET /protected": {
        accepts: {
          scheme: "exact",
          price: "$0.10",
          network: "eip155:1329",
          payTo: "0xYourAddress",
        },
        description: "Access to premium content",
      },
    },
    resourceServer,
  ),
);
```

Two things to watch for. Route keys now include the HTTP verb (`"GET /protected"` rather
than `"/protected"`), and `payTo` moved from the first positional argument into each
route's `accepts` block, so different routes can pay out to different addresses.

Import `ExactEvmScheme` from `@x402/evm/exact/server` on the server side, and from
`@x402/evm` on the client side.

### hono

Identical shape to express, importing `paymentMiddleware` and `x402ResourceServer` from
`@x402/hono`.

### next

v2 renames the entry point from `paymentMiddleware` to `paymentProxy`, and the
conventional file moves from `middleware.ts` to `proxy.ts`.

Before, in `middleware.ts`:

```typescript
import { paymentMiddleware } from "@sei-js/x402-next";

export const middleware = paymentMiddleware("0xYourAddress", {
  "/protected": { price: "$0.01", network: "sei" },
});

export const config = { matcher: ["/protected/:path*"] };
```

After, in `proxy.ts`:

```typescript
import { paymentProxy, x402ResourceServer } from "@x402/next";
import { HTTPFacilitatorClient } from "@x402/core/server";
import { ExactEvmScheme } from "@x402/evm/exact/server";

const facilitatorClient = new HTTPFacilitatorClient({ url: "https://x402.org/facilitator" });
const resourceServer = new x402ResourceServer(facilitatorClient).register(
  "eip155:1329",
  new ExactEvmScheme(),
);

export const proxy = paymentProxy(
  {
    "/protected": {
      accepts: {
        scheme: "exact",
        price: "$0.01",
        network: "eip155:1329",
        payTo: "0xYourAddress",
      },
      description: "Access to protected content",
    },
  },
  resourceServer,
);

export const config = { matcher: ["/protected/:path*"] };
```

## Coinbase facilitator

`@sei-js/coinbase-x402` was a scope rename of `@coinbase/x402` with no Sei-specific
changes, so switch the import back. The exported API is unchanged: `facilitator` and
`createFacilitatorConfig(apiKeyId, apiKeySecret)`, still reading `CDP_API_KEY_ID` and
`CDP_API_KEY_SECRET` from the environment.

Its `FacilitatorConfig` output plugs directly into v2's facilitator client:

```typescript
import { facilitator } from "@coinbase/x402";
import { HTTPFacilitatorClient } from "@x402/core/server";

const facilitatorClient = new HTTPFacilitatorClient(facilitator);
```

## Wallet and client helpers

The fork exported Sei-specific viem helpers from `@sei-js/x402` (`createClientSei`,
`createSignerSei`, `createClientSeiTestnet`, `createSignerSeiTestnet`). These have no v2
equivalent and are not needed: construct a viem account with `privateKeyToAccount` and let
the registered `network` determine the chain.

## Further reading

- [Upstream repository](https://github.com/x402-foundation/x402)
- [Network and token support](https://github.com/x402-foundation/x402/blob/main/docs/core-concepts/network-and-token-support.mdx)
- [PR #3227](https://github.com/x402-foundation/x402/pull/3227), which added the Sei
  default stablecoins upstream
