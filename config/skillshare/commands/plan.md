---
description: Create detailed to-do list broken into smallest logical steps following best practices
---

# Plan - Detailed Task Breakdown

Create a comprehensive to-do list using Claude Code's To Do feature. Break down the work into the smallest logical steps that follow coding best practices and preserve existing functionality.

## Instructions

1. **Analyze Current State**
   - Review existing codebase and functionality
   - Identify what needs to be built/modified
   - Note any dependencies or constraints

2. **Create Task List**
   - Break down into smallest logical steps
   - Order tasks by best practices (e.g., data layer → business logic → UI)
   - Number tasks hierarchically (1.1, 1.2, 2.1, etc.)
   - Ensure each step is testable

3. **Add to Claude Code To Do**
   - Use proper task format
   - Include acceptance criteria for each task
   - Mark dependencies between tasks

## Important Rules

- **Testing**: User handles all testing unless explicitly told otherwise - you only write code
- **Git**: Never push to GitHub until user explicitly approves
- **Existing Functionality**: Ensure no breaking changes
- **Order**: Tasks must be completed sequentially

## Output Format

Present the plan clearly, then add it to the To Do feature for tracking.