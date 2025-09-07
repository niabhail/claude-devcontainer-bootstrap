# Claude Code Setup Guide

Welcome to enterprise-grade AI development! Choose your setup path below.

## ⚡ Quick Start 

**Just want to get coding?** Pick your experience level:

### For Advanced Developers (2 minutes)
```bash
/sc:load && /models  # Load framework + select Sonnet
/sc:initialize      # Enterprise AI setup with multi-agent orchestration
```
→ Jump to [Advanced Setup](#advanced-setup) for full enterprise features

### For Beginners (3 steps, 2 minutes)  
```bash
/models            # Step 1: Select Sonnet model
/sc:load           # Step 2: Load development tools  
/sc:initialize     # Step 3: Basic setup with learning support
```
→ Continue to [Beginner Setup](#beginner-setup) for detailed guidance

---

## 🌱 Beginner Setup

**New to development?** Don't worry! Follow these simple steps with explanations.

## ⚡ Step 1: Choose Your Model

**What this does**: Sets up Claude Code to use the best AI model for development.

```
/models
```
**Instructions**: When the menu appears, select **Sonnet** (it's the best balance of speed and intelligence).

## ⚡ Step 2: Initialize Your Development Environment

**What this does**: Sets up enhanced coding assistance with specialized tools.

```
/sc:load
```
**What to expect**: You'll see messages about loading development tools. This is normal!

## ⚡ Step 3: Get Coding Help

**What this does**: Activates your AI coding assistant to help with your project.

```
/sc:initialize

I'm new to development and want to start a simple project. Please set up:
- Basic coding assistance
- Code explanations when I need help
- Simple project guidance
- Save my progress automatically

Help me understand what tools are now available and how to use them for learning.
```

**What to expect**: Claude will confirm your setup and explain the basic features available to you.

---

## 🚀 Advanced Setup

**Experienced with development?** Here are the enterprise-grade features available to you.

### Multi-Expert Strategic Analysis

**Use Case**: Business requirements, product strategy, technical architecture planning

```bash
/sc:analyze @your_requirements.md --business-panel

Use SuperClaude business analysis framework:
- Multi-expert business analysis (Porter, Christensen, Drucker frameworks)
- Strategic requirement evaluation and technical architecture design
- Risk assessment and compliance analysis with /sc:security persona
- Implementation planning with /sc:backend and /sc:frontend personas
- Quality strategy development with /sc:quality persona

Generate comprehensive analysis with strategic insights and implementation roadmap.
```

### Enterprise Team Orchestration

**Use Case**: Large development teams, complex projects, multi-persona coordination

```bash
/sc:team-setup

Configure specialized SuperClaude personas for enterprise development:

**Primary Personas**: Map requirements to optimal combinations
- Architecture decisions → /sc:architect 
- Frontend development → /sc:frontend + /sc:ui-expert
- Backend services → /sc:backend + /sc:system-architect  
- Security & compliance → /sc:security + /sc:devops
- Quality assurance → /sc:quality + /sc:performance

**Enterprise Capabilities**:
- Cross-persona validation and quality gates
- Systematic handoffs between development phases
- 6 integrated MCP servers (context7, morphllm, playwright, serena, etc.)
- Token optimization and session persistence for large-scale projects

Generate persona-specific workflows for immediate enterprise use.
```

### TaskMaster Integration (If Enabled)

**Use Case**: Project management integration, task tracking, team coordination

```bash
Initialize TaskMaster AI for this project:
- Main model: claude-code/sonnet (no API key needed)
- Research model: perplexity/sonar-pro  
- Fallback model: claude-code/opus
- Enable VS Code, Git, and Claude Code integration
- Prioritize efficient model usage

# Integration workflow:
1. Convert SuperClaude analysis into actionable development tasks
2. Create comprehensive task breakdown with complexity estimation
3. Set up task prioritization and dependency tracking
4. Configure automated progress tracking and reporting
5. Link TaskMaster tasks with SuperClaude personas for specialized execution
```

### Advanced Workflow Optimization

**Use Case**: Production-scale development, token optimization, session management

```bash
/sc:workflow-optimize

Set up ongoing enterprise SuperClaude workflows:
- Session Management: Automatic checkpoints and project memory persistence
- Token Optimization: Ultracompressed mode for large-scale operations  
- Quality Integration: Continuous validation with persona cross-checks
- Productivity Enhancement: Specialized commands for common development tasks
- Documentation: Automatic technical documentation generation

# TaskMaster Integration (if enabled):
- Daily progress reports from SuperClaude persona work
- Sprint planning with SuperClaude architectural analysis
- Quality gates linking task completion with persona validation
```

---

## 📚 References

### Next Steps After Setup

**🌱 For Beginners**:
1. **Ask for help**: Just type normal questions like "How do I create a button?"
2. **Get explanations**: Ask "Explain this code" and select any code you don't understand
3. **Save your work**: Type `/sc:save` occasionally to save your progress
4. **Basic commands**: `/sc:help`, `/sc:status`, and just ask natural questions

**🎓 Ready for More?** Graduate to enterprise features:
- **Strategic Analysis**: `/sc:analyze --business-panel` 
- **AI Team Coordination**: `/sc:team-setup` 
- **Architecture Planning**: `/sc:architect`

**🚀 For Advanced Users**: Jump directly to the enterprise capabilities in the [Advanced Setup](#advanced-setup) section.

### Command Reference

<details>
<summary>📖 Complete SuperClaude Commands</summary>

**Core Commands:**
- `/sc:load` - Load project context and session state
- `/sc:save` - Save current session and project state  
- `/sc:status` - Show framework status and active components
- `/sc:help` - Display all available SuperClaude commands

**Development Personas:**
- `/sc:frontend` - Frontend/UI development specialist
- `/sc:backend` - Backend/server development specialist
- `/sc:architect` - System architecture and design patterns
- `/sc:security` - Security analysis and compliance
- `/sc:quality` - Testing strategies and quality assurance

**Analysis & Optimization:**
- `/sc:analyze` - Deep technical and business analysis
- `/sc:business-panel` - Multi-expert business analysis mode
- `/sc:optimize` - Performance optimization and code improvement
- `/sc:refactor` - Systematic code refactoring and cleanup
- `/sc:document` - Generate technical documentation

**Enterprise Features:**
- `/sc:team-setup` - AI agent orchestration for enterprise teams
- `/sc:workflow-optimize` - Production-scale workflow optimization

</details>

### Setup Checklists

**🌱 Beginners** (3 steps, 2 minutes):
- [ ] Start with [Quick Start](#quick-start) → Beginner path
- [ ] Follow [Beginner Setup](#beginner-setup) detailed guidance  
- [ ] **Done!** Start asking coding questions
- [ ] Graduate to [Advanced Setup](#advanced-setup) when ready

**🚀 Advanced Developers** (2 minutes):
- [ ] Use [Quick Start](#quick-start) → Advanced path  
- [ ] Explore [Advanced Setup](#advanced-setup) enterprise features
- [ ] Configure TaskMaster if enabled in devcontainer
- [ ] **Done!** Start with `/sc:analyze --business-panel`

**Need Help?**
- Type `/sc:help` to see all available commands
- Ask questions like "How do I get started with my first project?"  
- Check your devcontainer configuration for enabled features