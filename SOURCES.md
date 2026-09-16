# Sources

The whitelist. `/research` searches with `allowed_domains` built from the
**Domain** column, and anything not listed here isn't evidence. To add a
source, add a row — that's the whole process.

A path-scoped domain (`aws.amazon.com/builders-library`) is searched by host,
then each result's URL is checked against the path before it counts.

## Tiers

| Tier | Means | Can carry a claim alone? |
|---|---|---|
| **T1 Validated** | Peer-reviewed venues, systematic reviews, standards bodies, refereed reference works | Yes |
| **T2 Established practice** | Named experts and institutions with a public track record; practitioner writing that cites or generated evidence | Yes, for engineering and design practice. Not for scientific claims. |
| **T3 Lead** | Preprints and unreviewed work | No — marked *unreplicated*. Look for the published version first. |

Evidence order, when sources disagree: systematic review / meta-analysis >
replicated primary study > single primary study > standard or spec >
T2 practice > T3 preprint.

## Lookup tools

For finding and checking sources. Never cited themselves.

| Tool | Domain | Use for |
|---|---|---|
| Semantic Scholar | semanticscholar.org | Citation counts, published version of a preprint |
| DBLP | dblp.org | Where a CS paper actually appeared |
| DOI resolver | doi.org | Canonical link for any paper |
| PhilPapers | philpapers.org | Philosophy literature index |
| Google Scholar | scholar.google.com | Discovery only |
| Wikipedia | wikipedia.org | Discovery only — follow it to the real source |

## Cross-domain

| Source | Domain | Tier | Notes |
|---|---|---|---|
| arXiv | arxiv.org | T3 | Preprints. Check DBLP / Semantic Scholar for the published version. |
| Nature Portfolio | nature.com | T1 | Includes Nature Reviews journals |
| Science (AAAS) | science.org | T1 | |
| PNAS | pnas.org | T1 | |
| Annual Reviews | annualreviews.org | T1 | Best entry point into an unfamiliar field |
| Oxford Academic | academic.oup.com | T1 | Journals only; OUP blog is not a source |
| Cambridge Core | cambridge.org | T1 | Journals and scholarly books |
| JSTOR | jstor.org | T1 | |
| MIT Press Direct | direct.mit.edu | T1 | Includes Neural Computation, Linguistic Inquiry |

## Software

| Source | Domain | Tier | Reach for it when |
|---|---|---|---|
| ACM Digital Library | dl.acm.org | T1 | Systems, PL, databases, SE — SOSP, OSDI, SIGMOD, PLDI, ICSE |
| ACM Queue / CACM | queue.acm.org, cacm.acm.org | T2 | Practitioner essays from people who built the thing |
| USENIX | usenix.org | T1 | OSDI, NSDI, ATC, FAST, Security — papers are free |
| IEEE Xplore | ieeexplore.ieee.org | T1 | |
| VLDB Endowment | vldb.org | T1 | PVLDB — databases, free |
| CIDR | cidrdb.org | T1 | Database systems vision papers |
| IETF / RFC Editor | rfc-editor.org, datatracker.ietf.org | T1 | Protocol behavior — the spec, not a blog about it |
| W3C | w3.org | T1 | Web standards |
| NIST | nist.gov, nvlpubs.nist.gov | T1 | Crypto, security controls, SP 800 series — 800-92 logs, 800-122 PII |
| OWASP | owasp.org, cheatsheetseries.owasp.org | T2 | Application security practice — Logging Cheat Sheet |
| Martin Fowler | martinfowler.com | T2 | Architecture patterns, refactoring, evolutionary design, bliki |
| DesignGurus | designgurus.io | T2 | System design patterns and interview-shaped tradeoffs. Corroborate numbers with T1. |
| AWS Builders' Library | aws.amazon.com/builders-library, builder.aws.com, d1.awsstatic.com/builderslibrary | T2 | Operating distributed systems at scale. The original URLs redirect to builder.aws.com, which renders empty to fetchers — read the PDF copies on d1.awsstatic.com |
| Google SRE books | sre.google | T2 | Reliability, SLOs, incident practice |
| Jepsen | jepsen.io | T2 | What a database actually guarantees under partition |
| All Things Distributed | allthingsdistributed.com | T2 | Werner Vogels — primary source on Dynamo-lineage decisions |
| Microsoft Research | microsoft.com/en-us/research | T1 | Papers only; path-scoped — verify the URL |
| Google Research | research.google | T1 | Papers only |
| Designing Data-Intensive Applications | dataintensive.net | T2 | Kleppmann; follow its references to T1 |
| Brendan Gregg | brendangregg.com | T2 | Performance methodology, observability |
| The Morning Paper archive | blog.acolyer.org | T2 | Paper summaries — cite the paper, not the summary |
| Martin Kleppmann | martin.kleppmann.com | T2 | Author copies of his papers and essays |
| Microservices.io | microservices.io | T2 | Chris Richardson — canonical microservice pattern write-ups |
| AWS Prescriptive Guidance | docs.aws.amazon.com/prescriptive-guidance | T2 | Named cloud design patterns |
| PostgreSQL docs | postgresql.org/docs | T2 | Primary for Postgres behavior — WAL, replication slots, isolation |
| MySQL docs | dev.mysql.com/doc | T2 | Primary for MySQL behavior — binlog, InnoDB |
| Apache Kafka docs | kafka.apache.org | T2 | Primary for Kafka semantics — idempotent producers, transactions |
| Debezium docs | debezium.io | T2 | Primary for Debezium behavior — snapshots, outbox router |
| AWS service docs | docs.aws.amazon.com | T2 | Primary for AWS behavior — quotas, defaults, scaling semantics, RDS Proxy pinning |
| AWS pricing | aws.amazon.com/*/pricing | T2 | List prices. Path-scoped; always cite Region and fetch date, prices move |
| AWS What's New | aws.amazon.com/about-aws/whats-new | T2 | When a capability shipped |
| AWS service blogs | aws.amazon.com/blogs | T2 | Feature internals by the service team; part-promotional, corroborate with docs |
| Azure Architecture Center | learn.microsoft.com/en-us/azure/architecture | T2 | Named cloud design patterns — async request-reply, claim check, valet key |
| Google AIPs | google.aip.dev | T2 | API design standards — long-running operations, pagination, errors |
| Python docs | docs.python.org | T2 | Primary for CPython, asyncio, and GIL behavior |
| asyncpg docs | magicstack.github.io/asyncpg | T2 | Primary for asyncpg — statement cache, pool reset |
| Slack developer docs | docs.slack.dev, api.slack.com | T2 | Slack platform limits and behavior |
| Brandur Leach | brandur.org | T2 | Postgres operational behavior with his own measurements — queues, MVCC, idempotency keys |

## AI systems

Model-provider docs are primary for how that API behaves — limits, pricing,
caching — and change often, so cite the fetch date. They say nothing about
model quality; that needs an eval or a refereed benchmark.

| Source | Domain | Tier | Reach for it when |
|---|---|---|---|
| Claude Platform docs | platform.claude.com/docs | T2 | Claude API rate limits, spend caps, batches, prompt caching, service tiers |
| PyTorch docs | docs.pytorch.org, github.com/pytorch/pytorch | T2 | CPU threading, quantization, loading. Hosted pages can render empty — read the `docs/source` files in the repo |
| Hugging Face docs | huggingface.co/docs | T2 | transformers pipelines, Optimum, safetensors |
| spaCy docs | spacy.io | T2 | Pipeline batching and multiprocessing |
| ONNX Runtime docs | onnxruntime.ai/docs | T2 | CPU quantization and thread management |
| Presidio docs | presidio.dataprivacystack.org | T2 | PII analyzer batching. Moved from microsoft.github.io/presidio |
| MLSys proceedings | proceedings.mlsys.org | T1 | ML systems papers |
| PMLR | proceedings.mlr.press | T1 | ICML, AISTATS papers |
| OpenReview | openreview.net | T1 accepted / T3 otherwise | ICLR, NeurIPS papers — check the decision; rejected and withdrawn submissions live here too |
| ACL Anthology | aclanthology.org | T1 | NLP papers — flag workshop papers |
| USENIX OSDI / SOSP via ACM | usenix.org, dl.acm.org | T1 | LLM serving systems — Orca, vLLM |

## Law and compliance

| Source | Domain | Tier | Reach for it when |
|---|---|---|---|
| EUR-Lex | eur-lex.europa.eu | T1 | EU law text — GDPR, AI Act. Cite article and recital |
| AICPA & CIMA | aicpa-cima.com | T1 | SOC 2 Trust Services Criteria. Download-walled; a mirror copy counts only if its edition is named |
| NIST | nvlpubs.nist.gov | T1 | Federal guidance on logs, PII, and AI risk (AI RMF) |

Legal and compliance text says what's required, not what's sufficient. An
investigation quotes it and says so; it doesn't give legal advice.

## Hardware

| Source | Domain | Tier | Reach for it when |
|---|---|---|---|
| IEEE Xplore | ieeexplore.ieee.org | T1 | ISSCC, VLSI, IEEE Micro, Computer |
| ACM Digital Library | dl.acm.org | T1 | ISCA, MICRO, ASPLOS, HPCA |
| USENIX | usenix.org | T1 | FAST (storage), security side channels |
| JEDEC | jedec.org | T1 | Memory standards (DDR, LPDDR, HBM) |
| PCI-SIG | pcisig.com | T1 | PCIe |
| RISC-V International | riscv.org | T1 | ISA specs |
| CXL Consortium | computeexpresslink.org | T1 | CXL spec |
| Hot Chips | hotchips.org | T2 | Vendor architecture disclosures — primary but promotional |
| Intel SDM / docs | intel.com | T2 | Primary for x86 behavior; ignore marketing pages |
| Arm Developer | developer.arm.com | T2 | Primary for Arm architecture |
| Agner Fog | agner.org | T2 | Microarchitecture measurements, instruction tables |
| CS:APP | csapp.cs.cmu.edu | T2 | Bryant & O'Hallaron — the systems baseline |
| SemiAnalysis | semianalysis.com | T3 | Industry economics; opinion-heavy, often paywalled |

## Philosophy

| Source | Domain | Tier | Reach for it when |
|---|---|---|---|
| Stanford Encyclopedia of Philosophy | plato.stanford.edu | T1 | Refereed, maintained. First stop for any concept. |
| Internet Encyclopedia of Philosophy | iep.utm.edu | T1 | Peer-reviewed; good second view |
| Routledge Encyclopedia of Philosophy | rep.routledge.com | T1 | Often paywalled |
| PhilArchive | philarchive.org | T3 | Preprints and author copies — find the journal version |
| Oxford / Cambridge / JSTOR | see Cross-domain | T1 | Mind, Noûs, Phil Review, JPhil, Ethics |
| Project Gutenberg | gutenberg.org | T1 | Primary texts in the public domain — cite the edition |
| Perseus | perseus.tufts.edu | T1 | Classical primary texts |

Philosophy has no "validated" in the empirical sense. T1 here means refereed
and representative of the literature; an investigation reports positions and
their strongest objections, not a winner.

## Design

| Source | Domain | Tier | Reach for it when |
|---|---|---|---|
| ACM CHI / DIS / CSCW | dl.acm.org | T1 | HCI research |
| Nielsen Norman Group | nngroup.com | T2 | Usability research and heuristics, with study data |
| Baymard Institute | baymard.com | T2 | Large-sample e-commerce UX research |
| W3C WAI / WCAG | w3.org | T1 | Accessibility — the standard |
| Interaction Design Foundation | interaction-design.org | T2 | Encyclopedia chapters by named academics |
| Apple HIG | developer.apple.com | T2 | Platform conventions — primary for Apple platforms |
| Material Design | m3.material.io | T2 | Platform conventions — primary for Android |
| Laws of UX | lawsofux.com | T3 | Discovery only — follow each law to its source study |
| Human Factors (HFES) | journals.sagepub.com | T1 | Perception, ergonomics, cognitive load |
| Journal of Vision | jov.arvojournals.org | T1 | Visual perception, open access |

## Biology

| Source | Domain | Tier | Reach for it when |
|---|---|---|---|
| Cochrane Library | cochranelibrary.com | T1 | Systematic reviews — top of the evidence order for health |
| PubMed | pubmed.ncbi.nlm.nih.gov | T1 | Finding any biomedical paper |
| PubMed Central / NCBI Bookshelf | ncbi.nlm.nih.gov | T1 | Full text; Bookshelf for textbooks (Alberts, etc.) |
| Cell Press | cell.com | T1 | |
| eLife | elifesciences.org | T1 | Open reviews published alongside papers |
| PLOS | journals.plos.org | T1 | |
| NEJM | nejm.org | T1 | Clinical trials |
| The Lancet | thelancet.com | T1 | Clinical and global health |
| BMJ | bmj.com | T1 | Clinical, evidence-based medicine |
| WHO | who.int | T1 | Guidelines and global statistics |
| NIH | nih.gov | T1 | Institute fact sheets, ODS for supplements |
| UniProt / Ensembl / PDB | uniprot.org, ensembl.org, rcsb.org | T1 | Protein, genome, structure data |
| bioRxiv / medRxiv | biorxiv.org, medrxiv.org | T3 | Preprints — health claims from these are never load-bearing |
| Examine | examine.com | T2 | Supplement evidence summaries — cite the studies it links |

Journals outside this list: accept only if indexed in PubMed/MEDLINE, and say
so. Watch for predatory publishers.

## Never cited

Not evidence, even when they agree. Search results from these are ignored.

- Aggregated blogging: medium.com, dev.to, hashnode.dev, substack.com,
  towardsdatascience.com, hackernoon.com, dzone.com
- Tutorial mills: geeksforgeeks.org, tutorialspoint.com, w3schools.com,
  javatpoint.com, simplilearn.com
- Forums and social: reddit.com, quora.com, stackoverflow.com (as evidence —
  fine for finding an API detail), linkedin.com, x.com, twitter.com
- Health content sites: healthline.com, webmd.com, mindbodygreen.com
- Vendor marketing pages and "what is X" SEO explainers on any domain
- AI-generated summaries, including other assistants' answers

Exception: a post by the primary author of the work under discussion, on any
platform, is T3 — the author explaining their own paper or system. Label it.
