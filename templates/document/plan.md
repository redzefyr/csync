---
csync: plan/1
status: active
status_note: |
  {{STATUS_NOTE}}
next: |
  {{NEXT}}
blocked: []
pairs: []
---

# {{TITLE}}

{{ONE PARAGRAPH: what this pipeline is for, and what "done" would mean.}}

<!--
  Filename: plans/<planned>-<advanced>-<slug>.md
    planned  = the day this pipeline was opened
    advanced = the day it last actually MOVED. Fixing a banner, correcting a
               typo, touching it during cleanup are NOT progress. If the date
               rises for those, "how long has this been parked" dies, and that
               signal is the only reason this name exists.

  status: active | waiting | parked        <- closed set, this is what gets counted
  status_note: the status in the words of the session that did the work.
               Never summarised, never translated.
  blocked: []  when nothing. Otherwise a list of `- |` block scalars.
  pairs:   []  when none. Otherwise:
             - repo: other-repo-name
               what: |
                 a description of the other side, NEVER a bare slug

  Every prose value uses `|`. A plain scalar breaks on a colon, a leading `#`,
  a quote or a `[`, and all four are everywhere in these documents.

  Do not leave finished sections here. Keep a one-line conclusion and push the
  evidence into docs/ -- that is the only thing stopping a plan from swelling
  into a decision archive.

  Full rules: references/document-format.md
-->
