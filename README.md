# library

A personal knowledge library for Claude Code — software, hardware, philosophy,
design, biology — and one skill, `/research`, that reads it, grows it, and
turns research into something worth reading.

```
/research <topic | url | question>     investigate, contrast with the library, file what's new
/research repo [subsystem]             hold this repo's architecture up against the library
/research add <url | doi | arXiv id>   file one source, no investigation
/research ask <question>               answer from the library alone, no web
```

It also fires without the slash: "research this architecture and contrast it
with our knowledge base" is enough.

## The loop

```
question ──▶ read the library ──▶ gather evidence (SOURCES.md only)
                                          │
   notes ◀── file what's durable ◀── contrast: Conflicts · Extends · Confirms · New
                                          │
                              investigation.md ──▶ artifact (offered)
```

Every investigation reads the library first and writes back to it. The
contrast is the point: what moved relative to what you already believed.
Conflicts land in the note's **Tensions** section instead of overwriting it,
so a disagreement stays visible until you settle it.

## Layout

```
SOURCES.md          the whitelist — tiers, domains, and what's never cited
INDEX.md            every note, one line each
domains/<d>/        README with the areas; notes at <area>/<slug>.md
investigations/     YYYY-MM-DD-<slug>.md, plus .html when published
templates/          note.md, investigation.md, investigation.html
skill/SKILL.md      /research
install.sh          links skill/ into every Claude config dir
```

## Sources

`SOURCES.md` is binding. Searches run with `allowed_domains` drawn from it, so
results from Medium, tutorial mills, and SEO explainers never enter the
evidence. Three tiers: **T1** peer-reviewed and standards, **T2** established
practice (Martin Fowler, DesignGurus, AWS Builders' Library, NN/g), **T3**
preprints like arXiv, always labeled and never load-bearing alone. Adding a
source is adding a row.

## Reading

Investigations are sized for a Sunday afternoon or a gap between meetings:
900–1,500 words, 5–8 minutes, bottom line first, headings that state findings.
Published artifacts share one design (`templates/investigation.html`) so they
read as a series, not a pile.

## Install

```bash
./install.sh                           # every ~/.claude and ~/.claude-* dir
./install.sh ~/.claude-juxtapose       # or name them
```

The skill is a symlink, so edits here are live in every account at once. It
finds the library by resolving its own link; set `KB_ROOT` only to point it at
a different copy.

On a machine without this repo: clone it anywhere, run `./install.sh`.

## Why it's shaped this way

anvil had a knowledge base and dropped it (anvil #10): 8 citations across 2 of
9 repos, bound to `/blueprint`, never reaching a decision. Three changes answer
that:

- **Not bound to a pipeline.** A standalone skill works in personal repos, work
  repos, and outside any repo, under any config dir.
- **Research writes back.** The old KB was read-only grounding someone had to
  curate by hand. Here every investigation files its durable findings, so the
  library grows from use.
- **Output is for reading, not citing.** The deliverable is an investigation
  you'd actually open, not a citation in a plan file.

Not part of anvil or jxp-skills, and neither build touches it.
