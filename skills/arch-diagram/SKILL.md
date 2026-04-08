---
name: arch-diagram
description: Generate system architecture diagrams (C4, component, security, deployment, dependency) using Mermaid
metadata:
  author: team
  version: 1.0.0
  source: adapted from ai-cursor-init
---

# Generate Architecture Diagram

Generate system architecture diagrams showing components, services, and their relationships using Mermaid notation.

## Usage

```
/arch-diagram                          # Full architecture, google style (default)
/arch-diagram enterprise               # Full architecture, enterprise style
/arch-diagram arc42                    # Full architecture, arc42 style
/arch-diagram security                 # Security architecture diagram
/arch-diagram deployment               # Deployment/infrastructure diagram
/arch-diagram dependency               # External dependency diagram
/arch-diagram component                # Component relationship diagram
/arch-diagram security enterprise      # Security diagram, enterprise style
/arch-diagram for the API subsystem    # Focused on specific area
```

## Argument Parsing

Parse `$ARGUMENTS` as follows:

**First word** — diagram type (default: `architecture`):
- `enterprise`, `arc42` → full architecture with that template style
- `security` → security architecture diagram
- `deployment` → deployment/infrastructure diagram
- `dependency` → external dependency diagram
- `component` → component relationship diagram
- anything else → treat as focus description for full architecture

**Second word** (if present) — template style:
- `google` → Google style (clean, minimal)
- `enterprise` → Enterprise style (comprehensive, TOGAF)
- `arc42` → Arc42 standard (structured, formal)
- Default: `google`

## Process

You are a system architecture documentation expert. When this skill is invoked:

1. **Analyze the project structure** to identify:
   - Major components and modules
   - Services and microservices
   - Frontend/backend separation
   - External integrations and third-party services
   - Data flow patterns

2. **Scan for infrastructure signals**:
   - API endpoints and routes
   - Background workers/tasks
   - Message queues
   - Cache layers
   - Database connections
   - Configuration files (docker-compose.yml, k8s manifests, terraform, etc.)

3. **Identify the technology stack** from dependency files:
   - `pyproject.toml`, `requirements.txt`, `setup.py` (Python)
   - `package.json` (JavaScript/TypeScript)
   - `go.mod` (Go)
   - `Cargo.toml` (Rust)
   - `pom.xml`, `build.gradle` (Java)

4. **Detect the architecture pattern**:
   - **Monolithic**: Single deployment unit, shared database, layered architecture
   - **Microservices**: Multiple services, service discovery, API gateway pattern
   - **Serverless**: Function-as-a-Service, event-driven, managed services
   - **Jamstack**: Static frontend, API backend, CDN delivery

5. **Read the appropriate template** from `references/`:
   - `template_google.md` — Google style (default)
   - `template_enterprise.md` — Enterprise/TOGAF style
   - `template_arc42.md` — Arc42 standard
   - `template_component.md` — Component diagram template

6. **Generate Mermaid diagrams** filling in the template placeholders with discovered architecture

7. **Save output** to the appropriate location:
   - **Whole-project** (no subfolder focus): save under top-level `docs/`
     - Architecture → `docs/architecture.md`
     - Security → `docs/security.md`
     - Deployment → `docs/deployment.md`
     - Dependency → `docs/dependencies.md`
     - Component → `docs/components.md`
   - **Subfolder focus** (e.g., `/arch-diagram for tools/`): save co-located with the code in the target subfolder
     - e.g., `src/Kernel_Agent/tools/architecture.md`
     - This is consistent with the project's existing pattern of co-located docs (`AGENTS.md` per directory)

## Diagram Type Specifications

### Architecture (default)
Creates comprehensive architecture visualization with:
- System context diagram (C4 model level 1)
- Component relationships
- Data flow patterns
- Technology stack summary

### Security
Analyzes security implementation to create visualizations showing:
- Authentication/authorization mechanisms (OAuth, JWT, RBAC, ABAC)
- Security boundaries and trust zones (Internet, DMZ, App Tier, Data Tier)
- Data flow with security controls
- Encryption (in-transit, at-rest)
- Network security (firewalls, VPCs, security groups)
- Secrets management and audit logging

Color-code trust zones in the Mermaid diagram:
```
style Internet fill:#ff9999
style DMZ fill:#ffff99
style AppTier fill:#99ff99
style DataTier fill:#9999ff
```

### Deployment
Analyzes deployment configuration to show:
- Infrastructure components (containers, VMs, serverless functions)
- Network architecture and load balancing
- Scaling and redundancy configuration
- Cloud provider resources (ECS, RDS, S3, CloudWatch, etc.)

### Dependency
Maps external service dependencies:
- Third-party APIs and integrations
- Cloud services (storage, databases, caching)
- Authentication providers
- Monitoring and analytics services

### Component
Shows major components within the system:
- Presentation, Application, and Data layers
- Synchronous and asynchronous communication patterns
- Internal and external dependencies

## Output Format

All diagrams use Mermaid syntax in markdown code blocks. The output document should include:
1. The Mermaid diagram(s) in code blocks
2. Component/service descriptions
3. Technology stack details
4. Relevant architectural notes

Use `graph TD`, `graph LR`, `graph TB`, `sequenceDiagram`, or `flowchart TD` as appropriate for each diagram type.

## Notes

- For function-level flow diagrams, use `/code-viz` instead (complementary skill)
- Templates in `references/` use `{{PLACEHOLDER}}` syntax — replace all placeholders with actual discovered values
- Create the `docs/` directory if it doesn't exist

## Mermaid Diagram Design Rules

### 0. Iterate in a live renderer

Predicting dagre's layout from source is a losing game even for experienced humans. The intended workflow is **draft → render in mermaid.live → adjust → re-render**. Never assume a diagram is done just because the syntax is valid. When handing off a diagram to the user — especially in a long doc with multiple diagrams — explicitly tell them to render it in [mermaid.live](https://mermaid.live) or their VS Code Mermaid preview before accepting it, and offer to revise based on what they see.

### 1. Plan before you write syntax

- State the one question the diagram answers in a single sentence. If you can't, or if there are two questions, you need two diagrams.
- Draft the node list and edge list as plain text first. Audit them against the rules below. Only then emit Mermaid code. Writing Mermaid linearly while thinking produces hub-and-spoke messes.
- Count before drawing. Target ≤15 nodes and ≤20 edges per diagram. Above that, split or abstract.

### 2. Split by audience, anchor by name

- Use the C4 split: a *Context* diagram (the system as one box + its external dependencies) and a *Component* diagram (what's inside the box). Sequence diagrams handle temporal flow separately.
- The parent box becomes the child's frame. The single node representing the system in the Context diagram must reappear as the enclosing subgraph in the Component diagram, with the same name.
- Boundary edges must match verbatim across diagrams. Every external arrow leaving the system box in the Context diagram must reappear in the Component diagram with an *identical* label, sourced from a specific internal component. This is the contract that makes split diagrams feel like one system.
- Represent external systems in component diagrams as boundary stubs (using the `[[Name]]` subroutine shape) — visible but not re-expanded.

### 3. Control fan-out

- No node should have more than 4 edges (in + out combined). If it does, either introduce an intermediate node or group the targets into a subgraph and draw one edge to the group.
- Collapse parallel edges with identical labels into one edge to a group. Three "API calls" arrows from `Router` to `Gemini`, `Claude`, `GPT` should become one `prompts` edge to an `LLM Providers` subgraph.
- Hub nodes are a smell, not a feature. A node that touches everything usually means the diagram is conflating layers.

### 4. Subgraphs

- Maximum 4 subgraphs per diagram. No nesting. Every subgraph adds layout constraints the renderer must satisfy.
- Never put a single node in its own subgraph. Subgraphs are for grouping ≥2 related nodes.
- Use `direction TB` / `direction LR` inside a subgraph to control internal flow independently of the parent.

### 5. Edge labels

- Every edge gets a verb label unless the relationship is self-evident from the node names. `spawn trees`, `invoke`, `minimize` — not `-->` alone.
- One label per edge. Never duplicate the same label across parallel edges. Duplication is a signal to collapse via grouping.
- Boundary labels are part of the diagram contract — pick the wording carefully since it must match across diagrams.

### 6. Node labels

- Keep labels under ~25 characters wide. Wide nodes force the layout engine to spread everything out.
- Use `<br/>` subtitles sparingly — only when the second line genuinely disambiguates (e.g., a model version). Put roles and descriptions in surrounding prose, not in the node.
- Short, specific names beat long descriptive ones. `BenchmarkRunner` not `BenchmarkRunner<br/>Orchestrator`.

### 7. Layout direction

- Pick direction by data shape: pipelines and sequences → `LR`. Hierarchies and decompositions → `TB`. Don't fight the shape.
- Order matters. Dagre places nodes roughly in declaration order within a rank. Declare nodes and subgraphs in the order you want them to appear.
- Never use `~~~` invisible links to force layout. If you're reaching for them, the structure is wrong — restructure instead.

### 8. Styling

- Never rely on color or styling to convey meaning. Rendering themes vary across environments (chat UIs, VS Code, mermaid.live, exported PDFs). Structure and labels must carry the entire message.
- If styling is used at all, use one `classDef` for a meaningful category (e.g., "external system") — never ad-hoc per-node colors.

### 9. Pick the right diagram type

- `sequenceDiagram` for "what calls what in what order." If you find yourself adding numbered labels or implying time in a `graph`, switch.
- `classDiagram` for type/inheritance relationships.
- `graph` / `flowchart` for structure and dependencies only.

### 10. Pre-emit checklist

Before outputting the Mermaid code, verify:

1. The diagram answers exactly one question.
2. ≤15 nodes, ≤20 edges, ≤4 subgraphs, no nesting.
3. No node has >4 edges.
4. No parallel edges with identical labels.
5. Every edge has a verb label (or is self-evident).
6. No `<br/>` subtitle is doing work that prose could do.
7. No `~~~` invisible links.
8. No color or styling carries meaning.
9. If part of a split: the parent box name and all boundary edge labels match the companion diagram exactly.
10. A `sequenceDiagram` wouldn't express this better.

If any check fails, revise the node/edge list — not the syntax — and re-check.

### 11. Zoom provenance in prose

Every diagram beyond the Context level should open with a prose line stating exactly which node(s) from the parent diagram it expands — e.g., "Expands `Cycle Strategies` and `BenchmarkRunner` from the Component diagram."

### 12. Cross-diagram name audit

Before presenting diagrams to the user, verify that every node name and boundary edge label is consistent across all diagrams. If a Component diagram says `Cycle Strategies`, the zoom diagram must use exactly `Cycle Strategies` — not `CycleStrategy`, not `Strategy`. This is an internal self-check, not output in the final document.

### 13. Guidelines are targets, not hard cutoffs

Prefer slightly exceeding a guideline (e.g., 16 nodes instead of 15) over removing information the user wants shown. The node/edge limits exist to catch overloaded diagrams, not to force lossy compression.

### 14. Prefer nested bullets over sub-headers for short related items

When a section has 2-4 closely related topics (e.g., Authentication, Data Protection, Network Security under Security Considerations), use nested bullet points under the section header rather than separate `###` sub-headers. Sub-headers are for sections that need their own diagrams, tables, or multi-paragraph prose. If the content fits in 2-3 bullet points, it doesn't need its own header.