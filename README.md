![Seaport](img/Astonic-banner.png)

[![Foundry][foundry-badge]][foundry]
[![Astonic Core CI][ci-badge]][ci-link]

# Astonic Core

This repo contains the source code of the core smart contracts for the Astonic protocol. The repository is built with foundry which is used for the compilation and testing of the smart contracts.
It is a fork of [Mento](https://github.com/mento-protocol).

## What is Astonic?

The Astonic protocol is a smart contract platform built on the Planq blockchain that enables the creation of stable value digital assets. Stable assets created with Astonic can be classified as 'Hybrid stable assets' as they are algorithmic, transparent and backed by a over-collateralized, diversified portfolio of exogenous crypto assets([Astonic Reserve](https://reserve.astonic.io/)).

## Documentation

- [Protocol Documentation](https://docs.astonic.io/getting-started/quickstart)
- [Stability Whitepaper](https://docs.astonic.io/astonic-protocol-concepts/core-stability-framework)

## Getting Started

```bash
# Get the latest code
git clone git@github.com:astonic-io/astonic-core.git

# Change directory to the the newly cloned repo
cd astonic-core

# Install dev dependencies with yarn
yarn

# Install submodule dependencies with forge
forge install

# Compile the smart contracts with forge
forge build

# Run all tests with forge
forge test
```

#### Slither

Install slither, if not installed.

```bash
pip3 install slither-analyzer
```

Running slither locally requires you to build only a subset of packages:

```bash
forge clean
forge build --build-info --skip tests
slither . --foundry-ignore-compile
```

If you want to ignore a slither warning run:

```bash
slither . --foundry-ignore-compile --triage-mode
```

For triage mode, in which you can choose to ignore warnings which are added to `slither.db.json`.

[ci-link]: https://github.com/astonic-io/astonic-core/actions/workflows/ci.yml
[ci-badge]: https://github.com/astonic-io/astonic-core/actions/workflows/ci.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
