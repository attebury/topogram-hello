# Topogram Hello

Pure Topogram package for the neutral Hello/Greeting resource.

This package is for `topogram catalog copy`, not `topogram new`. It contains:

```text
topogram/
topogram.project.json
README.md
```

It intentionally does not contain executable `implementation/` code.

## Usage

After the catalog entry is available:

```bash
topogram catalog copy hello ./hello-topogram
cd ./hello-topogram
topogram check
```

The copied project is editable Topogram source. It can later be generated with a
template or maintained by an agent/human workflow.

## Verification

```bash
npm run pack:check
```

See [`CONSUMER_PROOF.md`](./CONSUMER_PROOF.md) for the verification standard
this repo must keep before publishing the pure topogram package.

The package smoke verifies that the packed package contains no `implementation/`
directory, validates the Topogram project, and exercises `topogram catalog copy`
with a local catalog fixture.
