# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Motion by Aiselu is an AI-powered chat application for physiotherapists that supports both voice and text communication. While designed for general conversation, it has specialized capabilities for generating structured SOAP reports from patient session descriptions. The project consists of a Python backend using Google ADK (Agents Development Kit) and a native iOS Swift frontend.

## Architecture

- **Backend**: Python 3.11+ with Google ADK agents, located in `backend/src/motion/`
- **Frontend**: Native iOS Swift chat app with voice/text input and specialized SOAP report features
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
# Edit .env with your API keys including LINKUP_API_KEY for exercise illustrations
```

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
- Conversational AI agent with specialized SOAP capabilities located at `backend/src/motion/agents/soap_agents/agent.py`
- Exercise illustration search implemented as a tool at `backend/src/motion/tools/exercise_illustration_tool.py`
- Agent handles general physiotherapy conversations and can generate structured SOAP reports when patient session data is provided

### Core Workflow
1. **General Chat Mode**: User communicates via voice/text with AI agent for general physiotherapy discussions
2. **SOAP Generation Trigger**: When user provides patient session information, agent automatically detects this and initiates SOAP report generation
3. **Clarification Process**: Agent asks clarifying questions if patient information is incomplete
4. **Exercise Illustration Selection**: For generated SOAP reports, agent searches for exercise images and presents options to user
5. **Final Report Creation**: User selects desired images and can export complete SOAP report as PDF

### External Dependencies
- Google ADK for agent framework
- Linkup AI Search API for exercise illustrations
- PostgreSQL + SQLAlchemy ORM (planned)
- Redis for caching (planned)
- Celery for task queues (planned)

## Development Notes

- The project includes both general conversational AI and specialized SOAP report generation
- iOS app uses native Speech framework for optimal voice recognition
- Backend uses `uv` for dependency management instead of pip/poetry
- Environment variables should be configured in `.env` file including LINKUP_API_KEY for exercise illustrations
- Agent uses structured message types for frontend rendering: `chat_message`, `soap_draft`, `exercise_selection`, `final_report`, `clarification_needed`
- Frontend implements chat-based UI with specialized components for SOAP workflow

## Current Implementation Status

### ✅ Completed Features
- **Backend**: Complete Google ADK agent with conversational AI and SOAP capabilities
- **iOS App**: Full SwiftUI chat interface with native voice recognition
- **API Integration**: Working communication between iOS app and ADK backend via `/run` endpoint
- **Structured Messaging**: JSON-based message system for dynamic UI rendering
- **Voice Input**: Native iOS Speech framework integration (works on physical devices)
- **Exercise Search**: Linkup AI integration for exercise illustration discovery
- **Message Parsing**: Extraction of structured JSON from agent markdown responses

### 🚧 In Progress / Known Issues
- **Voice Recognition**: Works on physical devices, has asset issues on iOS Simulator
- **Exercise Image Selection**: UI components built, workflow integration pending
- **PDF Export**: UI placeholder created, implementation pending
- **Error Handling**: Basic error display implemented, needs enhancement
- **Image Selection State**: Backend expects image selection responses, needs frontend completion

### 🔄 Next Development Steps
1. Complete exercise image selection workflow in iOS app
2. Implement PDF generation for final SOAP reports  
3. Add SSE streaming support for real-time responses (`/run_sse` endpoint)
4. Enhance error handling and user feedback
5. Add session persistence and chat history
6. Implement proper loading states and progress indicators
7. Add unit tests for both backend and frontend components

### 🧪 Testing Notes
- Backend server runs on `localhost:8000` with ADK CLI
- iOS app communicates via HTTP to local development server
- Voice recognition requires physical iOS device (simulator has speech asset limitations)
- Test general chat and SOAP generation workflows separately
- Agent successfully detects patient session context and switches modes automatically