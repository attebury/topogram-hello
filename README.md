# Topogram Hello

Pure Topogram package for the neutral Hello/Greeting resource.

This package is for `topogram copy` as a pure Topogram package, not as a runnable app clone. It contains:

```text
topo/
topogram.project.json
README.md
```

It intentionally does not contain executable `implementation/` code.

## Usage

After the catalog entry is available:

```bash
npm install --save-dev @topogram/cli
npx topogram doctor
npx topogram catalog show hello
npx topogram copy hello ./hello-topogram
cd ./hello-topogram
npx topogram source status --local
npx topogram check
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
directory, validates the Topogram project, and exercises `topogram copy`
with a local catalog fixture.
