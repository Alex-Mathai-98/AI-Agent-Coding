# Code Plan

<!-- 
Your primary responsibility is not just to output a functional plan, but a plan 
that leads to generated code that is "human-like"—the kind of code a thoughtful 
senior engineer would write by hand.

Why this matters: When production systems go down at 3 AM and a sleep-deprived 
developer needs to diagnose and fix the issue or risk losing their job, reading 
through simple, human-like code is far easier than navigating sprawling abstractions 
and over-engineered layers written by AI assistants. Debuggability saves careers.
-->

Plan the implementation for the following feature request, prioritizing simplicity and maintainability over abstraction:

$ARGUMENTS

## Guidelines

Before proposing any code plan, follow these principles:

**Think like a 100x engineer.** A 100x engineer always chooses the simplest possible solution. If a feature can be implemented with a few small changes, that's the path to take. Only when that's truly not possible should you consider a larger change. Simplicity is not a compromise—it's the goal.

**Minimize data classes.** Reuse existing data structures where possible. Only introduce a new class if no existing one fits and a plain dict/tuple won't suffice.

**Flatten inheritance.** Less inheritance = less complexity. No magic number—adopt inheritance only when it simplifies the code, never when it adds complexity. Composition/functions often beat inheritance.

**Reuse, don't reimplement.** Search the codebase for existing utilities or patterns that solve the problem. Call existing code rather than writing new versions.

**Let it fail.** Avoid defensive try-catch blocks scattered throughout the code. Place a single error boundary at the top-level API entry point (REST handler, CLI entrypoint, public method) to protect end users. Elsewhere, let exceptions propagate for easier debugging.

## Output

Provide a concise plan that includes:
1. Which existing code/classes to reuse
2. The minimal set of new code required
3. Where the top-level error boundary should live (if truly necessary)
4. A brief rationale for any new abstractions (if truly necessary)

**Save this plan to a file named `z-cpl-<NN>.md`** where `<NN>` is a random 2-digit number (00-99).