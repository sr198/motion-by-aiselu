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
- **Framework**: FastAPI (Python 3.11+)
- **AI/ML**: Google ADK (Agents Development Kit) with Gemini
- **Database**: PostgreSQL with SQLAlchemy ORM
- **Cache**: Redis
- **Task Queue**: Celery
- **Image Search**: Bing Image Search API via MCP

**Frontend:**
- **Framework**: Flutter
- **State Management**: TBD
- **Local Storage**: SQLite

## 🚀 Getting Started

### Prerequisites

- Python 3.11 or higher
- PostgreSQL 15+
- Redis 7+
- Flutter SDK (for frontend development)
- uv (Python package manager)

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
   # Edit .env with your API keys and configuration
   ```

4. **Start required services**
   ```bash
   # Using Docker Compose (recommended)
   docker-compose up -d postgres redis
   
   # Or install locally
   # - PostgreSQL: https://www.postgresql.org/download/
   # - Redis: https://redis.io/download
   ```

5. **Initialize the database**
   ```bash
   # Create database
   createdb motion_aiselu
   
   # Run migrations
   alembic upgrade head
   ```

6. **Run the backend server**
   ```bash
   uvicorn src.motion_aiselu.main:app --reload
   ```

   The API will be available at `http://localhost:8000`
   API documentation at `http://localhost:8000/docs`

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
   - Automatic detection of exercises mentioned in reports
   - Bing image search integration for finding relevant illustrations
   - Thumbnail preview and selection interface
   - Proper attribution and copyright compliance

4. **Report Management**
   - Save and edit generated reports
   - Export to PDF/Word formats
   - Patient history tracking
   - Secure cloud synchronization

### Workflow

1. **Start Session**: Physiotherapist begins a new patient session
2. **Dictate**: Record the interaction naturally
3. **Process**: AI converts transcript to SOAP report
4. **Review**: Edit and refine the generated report
5. **Enhance**: Add exercise illustrations if needed
6. **Export**: Save and share the final report

## 🛠️ Development

### Project Structure

```
backend/
├── src/motion_aiselu/
│   ├── agents/          # ADK agents for report generation
│   ├── tools/           # Tools for specific tasks
│   ├── api/             # FastAPI endpoints
│   ├── models/          # Database models
│   ├── services/        # Business logic
│   └── utils/           # Utilities and helpers
└── tests/               # Test suite
```

### Running Tests

```bash
# Backend tests
cd backend
pytest

# Run with coverage
pytest --cov=src/motion_aiselu

# Run specific test categories
pytest tests/unit
pytest tests/integration
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