# Claude Code Setup Prompts

Run these prompts manually in Claude Code after logging in and the devcontainer is ready.

## 1. Change Claude Code Default Model

```
/models
```
Then select Sonnet as the default model.

## 2. Initialize TaskMaster AI

```
Initialize TaskMaster AI for this project:
- Main model: claude-code/sonnet (no API key needed)
- Research model: perplexity/sonar-pro  
- Fallback model: claude-code/opus
- Enable VS Code, Git, and Claude Code integration
- Prioritize efficient model usage

Run the setup commands and verify everything works.
```

## 3. PRD Analysis & Task Planning

```
Help me analyze the Product Requirements Document (PRD) for this project:

1. Research and parse the PRD document
2. Extract key features and requirements
3. Create comprehensive development tasks using TaskMaster
4. Assess complexity and effort estimation for each task
5. Organize tasks by priority and dependencies

Please break down the PRD systematically and create a detailed task breakdown structure.
```

## 4. Generate Development Team Subagents

```
Based on the PRD requirements and task complexity analysis, generate specialized Claude subagents for my development team:

1. Analyze the technical requirements from the PRD
2. Identify key development roles needed (frontend, backend, devops, testing, etc.)
3. Create custom Claude subagent prompts tailored to each role
4. Include specific instructions, tools, and responsibilities for each subagent
5. Ensure subagents align with the project's tech stack and requirements
6. IMPORTANT: Configure subagents to use Context7 MCP for up-to-date information when relevant
   - Latest documentation lookups
   - Current best practices and patterns
   - Recent framework updates and changes
   - Security advisories and updates

Generate production-ready subagent configurations that my team can use immediately.
```

---

**Instructions:**
1. Run `/models` command and select Sonnet
2. Copy and paste each prompt into Claude Code chat in sequence
3. Provide the PRD document when prompted in step 3
4. Follow Claude's instructions to complete all setups
5. Save the generated subagent configurations for your team