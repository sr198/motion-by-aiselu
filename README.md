# Motion by Aiselu

A mobile application for physiotherapists that revolutionizes patient interaction documentation through voice dictation, AI-powered SOAP report generation, and intelligent exercise illustration integration.

## 🎯 Overview

Motion by Aiselu streamlines the documentation process for physiotherapists by:
- **Voice Transcription**: Dictate patient interactions naturally
- **AI-Powered Documentation**: Automatically generate structured SOAP reports
- **Smart Exercise Integration**: Search and attach relevant exercise illustrations
- **Time Efficiency**: Reduce documentation time from 20+ minutes to under 5 minutes

## 🏗️ Architecture

This is a monorepo containing both backend and frontend components:

```
motion-aiselu/
├── backend/          # Python FastAPI + Google ADK agents
├── frontend/         # Flutter mobile application
└── docs/            # Additional documentation
```

### Technology Stack

**Backend:**
- **Framework**: Python 3.11+ with Google ADK (Agents Development Kit)
- **AI/ML**: Google Gemini 2.0 Flash via ADK agents
- **Image Search**: Bing Search API via MCP (Model Context Protocol)
- **Package Management**: uv for fast Python dependency management
- **Architecture**: Agent-based with SOAP generation and exercise illustration subagents

**Frontend:**
- **Framework**: Flutter
- **State Management**: TBD
- **Local Storage**: SQLite

## 🚀 Getting Started

### Prerequisites

- Python 3.11 or higher
- uv (Python package manager) - Install from [astral.sh/uv](https://astral.sh/uv)
- Google API key for Gemini
- Bing Search API key for exercise illustrations
- Flutter SDK (for frontend development, when ready)

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/motion-aiselu.git
   cd motion-aiselu
   ```

2. **Set up the backend environment**
   ```bash
   cd backend
   uv venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   uv pip install -e ".[dev]"
   ```

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys:
   # - GOOGLE_API_KEY: Your Google API key for Gemini
   # - BING_SEARCH_API_KEY: Your Bing Search API key for exercise images
   ```

4. **Start MCP Server for Exercise Illustrations**
   ```bash
   # In a separate terminal, start the MCP Bing Search server
   cd backend
   uv add mcp-server-bing-search
   export BING_SEARCH_API_KEY=your_api_key_here
   uv run mcp-server-bing-search --transport sse --port 6030
   ```
   
   **Keep this running** - the exercise illustration feature requires this MCP server.

5. **Run the main application**
   ```bash
   # In another terminal
   cd backend
   source .venv/bin/activate
   python src/motion/main.py
   ```

### Frontend Setup

```bash
cd frontend
# Flutter setup instructions coming soon
```

## 📋 Features

### Core Functionality

1. **Voice Dictation**
   - Real-time transcription of physiotherapist-patient interactions
   - Support for multiple languages
   - Background noise reduction

2. **SOAP Report Generation**
   - AI-powered conversion of transcripts to structured SOAP format
   - Intelligent extraction of:
     - Subjective: Patient complaints and symptoms
     - Objective: Observable findings and measurements
     - Assessment: Professional evaluation
     - Plan: Treatment recommendations and exercises

3. **Exercise Illustration Integration**
   - Automatic detection of exercises mentioned in SOAP reports
   - AI-powered identification of exercises needing visual aids
   - Bing image search integration via MCP for finding relevant illustrations
   - Returns top 5 image results per exercise with URLs and descriptions
   - Designed for patient education and proper form demonstration

4. **Report Management**
   - Save and edit generated reports
   - Export to PDF/Word formats
   - Patient history tracking
   - Secure cloud synchronization

### Workflow

1. **Start Session**: Physiotherapist begins a new patient session
2. **Dictate**: Record the interaction naturally
3. **Process**: Main SOAP agent converts transcript to structured SOAP report
4. **Enhance**: Exercise illustration subagent automatically:
   - Analyzes the SOAP report for mentioned exercises
   - Searches for appropriate demonstration images
   - Returns top 5 relevant images per exercise
5. **Review**: Edit and refine the generated report with illustrations
6. **Export**: Save and share the final comprehensive report

## 🛠️ Development

### Project Structure

```
backend/
├── src/motion/
│   ├── agents/          # Google ADK agents
│   │   └── soap_agents/ # SOAP report generation agents
│   │       ├── agent.py                          # Main SOAP agent
│   │       ├── exercise_illustration_agent.py    # Exercise search subagent
│   │       └── prompts.py                        # Agent instructions
│   ├── api/             # FastAPI endpoints (planned)
│   ├── models/          # Database models (planned)
│   ├── tools/           # Agent tools for specific tasks
│   └── main.py          # Application entry point
└── tests/               # Test suite (planned)
```

### Code Quality

```bash
# Format code
black src tests
isort src tests

# Lint
ruff check src tests
mypy src
```

### Testing

```bash
# Run tests (when implemented)
cd backend
pytest

# Run with coverage
pytest --cov=src/motion
```

## 🔑 API Endpoints

### Core Endpoints

- `POST /api/v1/sessions/start` - Initialize a new dictation session
- `POST /api/v1/sessions/{session_id}/transcript` - Submit voice transcript
- `GET /api/v1/sessions/{session_id}/report` - Retrieve SOAP report
- `POST /api/v1/sessions/{session_id}/report/confirm` - Confirm final report
- `POST /api/v1/sessions/{session_id}/exercises/{exercise}/search` - Search exercise images
- `GET /api/v1/sessions/{session_id}/report/export` - Export report (PDF/Word)

Full API documentation available at `/docs` when running the server.

## 🔒 Security & Privacy

- **Data Encryption**: All data encrypted at rest and in transit
- **HIPAA Compliance**: Designed with healthcare privacy requirements in mind
- **Authentication**: JWT-based authentication for all API endpoints
- **Audit Logging**: Comprehensive logging of all data access
- **Data Retention**: Configurable retention policies

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Google ADK team for the agent framework
- Anthropic for AI consultation
- The physiotherapy community for valuable feedback

## 📞 Contact

- Website: [https://aiselu.ai/motion](https://aiselu.ai/motion)

## 🗺️ Roadmap

### Phase 1 (Current)
- [x] Basic voice transcription
- [x] SOAP report generation
- [ ] Exercise image search
- [ ] PDF export

### Phase 2
- [ ] Multi-language support
- [ ] Offline mode
- [ ] Template customization
- [ ] Practice management integration

### Phase 3
- [ ] AI-powered treatment suggestions
- [ ] Patient progress tracking
- [ ] Automated billing codes
- [ ] Telehealth integration

---

**Note**: This project is under active development. Features and APIs may change.