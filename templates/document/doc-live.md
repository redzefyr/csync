---
csync: doc/1
revise_when: |
  {{WHAT HAS TO CHANGE BEFORE THIS DOCUMENT IS WRONG}}
---

# {{TITLE}}

{{Body.}}

<!--
  docs/*.md is LIVE: when code or conventions change, this is revised with them.
  The test is "does this have to be corrected when code or conventions change?"
  Yes -> here. No -> docs/research/, which is archive and left as written.

  `revise_when` is that answer written down, so cleanup's "refresh docs/" step
  has something to check against instead of re-deriving it per file. If you
  cannot fill it in, this document is probably archive.

  Full rules: references/document-format.md
-->
