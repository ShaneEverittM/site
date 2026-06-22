+++
title = "Virtue-Driven Development Considered Harmful"
date = 2026-06-18
draft = true
+++

Software teams love virtues. But architectural values are not ideals; they are
bundles of trade-offs sold under a single flattering name.

- We chose Go because it's simple
- We reached for microservices because they scale
- We picked Rust because it's safe

These sound like arguments, but they are slogans until they say what they cost.
And some don't even survive the asking. "Simplicity" is rarely created or
destroyed — just moved somewhere you stop looking at it. "Scalability" is a bill
you may have no reason to pay.

Safety is the interesting one, because it survives. The borrow checker is a
genuine cost, paid in real units, and it still clears — which is exactly why it
makes a good ruler for the others.

<!-- TODO: spine of the piece — a virtue has to pass TWO tests:
       1. Does it name its trade-offs? (honesty)
       2. Is the thing even worth wanting? (merit)
     - Simple (Go): fails both. Hides costs; "simplicity" may just be
       redistributed, not created/destroyed.
     - Scalable (microservices): fails both. Hides costs; may not be needed.
     - Safe (Rust): the LOAD-BEARING example. Clears merit outright (safety is
       genuinely valuable), so only test 1 is left — and the costs (borrow
       checker, prototyping speed, hiring bar) are real but worth it.
     Rust isn't the exception to "trade-offs with marketing names" — it's the
     virtue that earns the name by being honest about the bill. It's what keeps
     the essay from collapsing into "never trust any virtue" / never build
     anything. Use it as the pivot into the body, not a closing punchline.

     Names for smuggling a trade-off in as axiomatically good — overlapping
     lenses on the same dodge, NOT a clean taxonomy (resist the urge to build a
     tree; the tidiness would itself be a "simple" smuggled in):
       - Glittering generality — vague virtue-word that wins assent before you
         can ask "simple for whom?" (warm framing — the one to lead with)
       - Begging the question / question-begging epithet — the loaded adjective
         presents the contested claim as a settled premise (cold/logical framing)
       - Persuasive definition — bake the goodness into the word's meaning so
         disagreeing sounds anti-virtue (most euphemistic-feeling)
       - Thought-terminating cliché — "keep it simple" ends analysis vs advances
       - Presupposing a frame — not really the parent of the others, but a
         related, less specific sibling: the word ships an unstated context in
         which it's obviously good; accept the word, accept the frame. Close-
         feeling to all of them without strictly containing any.
     Point: a virtue is MOST dangerous when it feels axiomatic — feeling
     axiomatic is how it dodges the trade-off question. Safety never gets to be a
     glittering generality (nobody finds the borrow checker warm), so it does the
     honest work the others skip.

     FORMAT / VOICE: practical, not flowery. Keep the philosophy above as
     scaffolding in my head, not on the page. The meat is a run of examples, each
     one shaped:
       quote you've DEFINITELY heard  ->  the trade-off it hides  ->  who pays it
     Make each cost land by naming the UNIT it's measured in (network calls, lines
     of err handling, config branches, onboarding hours). Vague costs read as
     opinion; a unit reads as proof. "it's slower" is weak; "you traded a 50ns
     function call for a 5ms RPC that can fail" is the lightbulb.
     Aim for 5-10 examples: with that many, the reader will feel at least ONE
     deep in their bones — that's the hit that sells the whole frame.

     Example shortlist (only keep ones the reader has actually heard):
       - "microservices so teams move independently" -> fn call became a network
         call: retries, partial failure, tracing, staging never fully up.
         Independence between teams bought with coupling between services.
       - "Go is simple" -> no enums/sum types, if err != nil x50. Language stayed
         simple by making YOUR code carry the complexity.
       - "no framework, just vanilla, less magic" -> you wrote a worse,
         undocumented framework inline; onboarding = read all of it.
       - "configurable so it's flexible" -> every option is a branch to test and a
         decision pushed onto the user. Flexibility = complexity with a sales team.
       - "monorepo, everything in one place" -> real honest trade-off to name.
       - "Postgres for everything, keep it boring" -> real honest trade-off.
     HONEST COUNTERWEIGHT: keep the Rust/safety section as the one whose bill is
     real AND worth paying. Earns reader trust; stops the piece reading as
     "every virtue is a lie." -->
