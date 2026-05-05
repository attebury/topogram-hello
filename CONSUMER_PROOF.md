# Consumer Proof

This repo publishes a pure topogram package for `topogram catalog copy`. It is
not a template and must not contain executable implementation code.

## Required Gate

```bash
npm run pack:check
```

The check must:

- install the Topogram CLI package pinned in `topogram-cli.version`;
- pack the topogram package;
- prove the tarball contains `topogram/` and `topogram.project.json`;
- prove the tarball does not contain `implementation/`;
- run catalog-copy verification with a local catalog fixture;
- run `topogram check` on the copied topogram.

## Not Acceptable

- Adding executable implementation to a pure topogram package.
- File-existence-only proof without `topogram check`.
- Stale hard-coded `@topogram/cli@x.y.z` literals instead of
  `topogram-cli.version`.
