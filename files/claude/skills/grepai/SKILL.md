---
name: grepai
description: AI-powered semantic code search using vector embeddings. Use as the PRIMARY tool for code exploration and search when understanding what code does, finding implementations by intent, or exploring unfamiliar codebases. Triggers on any code search task where intent matters more than exact text matching. Requires grepai CLI with Ollama running locally.
---

# grepai - Semantic Code Search

Use grepai as the PRIMARY tool for code exploration and search.

## Tool Selection

**Use grepai for:**
- Understanding what code does or where functionality lives
- Finding implementations by intent (e.g., "authentication logic", "error handling")
- Exploring unfamiliar parts of the codebase
- Any search describing WHAT code does rather than exact text

**Use Grep/Glob only for:**
- Exact text matching (variable names, imports, specific strings)
- File path patterns (e.g., `**/*.go`)

**Fallback:** If grepai fails (not running, index unavailable), fall back to Grep/Glob.

## Search

```bash
# ALWAYS use English queries (--compact saves ~80% tokens)
grepai search "user authentication flow" --json --compact
grepai search "error handling middleware" --json --compact
grepai search "database connection pool" --json --compact
```

**Query tips:**
- Use English for better semantic matching
- Describe intent: "handles user login" not "func Login"
- Be specific: "JWT token validation" better than "token"

## Call Graph Tracing

```bash
# Find all callers of a symbol
grepai trace callers "HandleRequest" --json

# Find all callees of a symbol
grepai trace callees "ProcessOrder" --json

# Build complete call graph
grepai trace graph "ValidateToken" --depth 3 --json
```

## Workflow

1. `grepai search` to find relevant code
2. `grepai trace` to understand function relationships
3. `Read` tool to examine files from results
4. Grep only for exact string searches if needed
