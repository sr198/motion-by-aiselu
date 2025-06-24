# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Motion by Aiselu is a mobile physiotherapy documentation app that uses AI to convert voice dictation into structured SOAP reports. The project consists of a Python backend using Google ADK (Agents Development Kit) and a Flutter frontend.

## Architecture

- **Backend**: Python 3.11+ with Google ADK agents, located in `backend/src/motion/`
- **Frontend**: Flutter mobile app (structure not yet implemented)
- **Package Management**: Uses `uv` for Python dependency management
- **AI Framework**: Google ADK with Gemini for agent-based processing

## Key Development Commands

### Backend Setup and Development
```bash
# Setup virtual environment and dependencies
cd backend
uv venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
uv sync

# Install in development mode with dev dependencies
uv pip install -e ".[dev]"

# Run the application
python src/motion/main.py
```

### Testing and Quality
Based on the README, these commands should be available:
```bash
# Run tests
pytest

# Run with coverage
pytest --cov=src/motion

# Format code
black src tests
isort src tests

# Lint
ruff check src tests
mypy src
```

### Environment Configuration
```bash
# Copy and configure environment variables
cp .env.example .env
# Edit .env with your API keys and configuration
```

### MCP Server Setup (Required for Exercise Illustrations)
The exercise illustration feature requires the Bing Search MCP server to be running:

```bash
# Install MCP Bing Search server
uv add mcp-server-bing-search

# Run the MCP server (in a separate terminal)
cd backend
export BING_SEARCH_API_KEY=your_api_key_here
uv run mcp-server-bing-search --transport sse --port 6030
```

The MCP server must be running on port 6030 before starting the main application.

## Project Structure

```
backend/src/motion/
├── agents/          # Google ADK agents for SOAP report generation
├── api/             # FastAPI endpoints (planned)
├── models/          # Database models (planned)
├── tools/           # Agent tools for specific tasks
└── main.py          # Application entry point
```

## Key Implementation Details

### Agent Architecture
- Uses Google ADK (Agents Development Kit) with Gemini
- Main SOAP agent located at `backend/src/motion/agents/soap_agents/agent.py`
- Exercise illustration subagent at `backend/src/motion/agents/soap_agents/exercise_illustration_agent.py`
- Agents handle the conversion of voice transcripts to structured SOAP reports with exercise illustrations

### Core Workflow
1. Voice dictation transcription
2. AI-powered SOAP report generation via agents
3. Exercise illustration search and integration
4. Report export and management

### External Dependencies
- Google ADK for agent framework
- Bing Image Search API for exercise illustrations
- PostgreSQL + SQLAlchemy ORM (planned)
- Redis for caching (planned)
- Celery for task queues (planned)

## Development Notes

- The project is in early development - many components mentioned in the README are not yet implemented
- Current implementation is minimal with basic structure in place
- Backend uses `uv` for dependency management instead of pip/poetry
- Environment variables should be configured in `.env` file
- The main application logic will be implemented as Google ADK agents