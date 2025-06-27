"""
Global pytest configuration and fixtures.
"""

import os
import pytest
from unittest.mock import Mock, patch
from typing import Dict, Any, List, Generator
import json


@pytest.fixture
def mock_env_vars() -> Generator[Dict[str, str], None, None]:
    """Mock environment variables for testing."""
    test_env = {
        "MODEL_GEMINI_2_0_FLASH": "test-model",
        "LINKUP_API_KEY": "test-linkup-key",
    }
    
    with patch.dict(os.environ, test_env, clear=False):
        yield test_env


@pytest.fixture
def sample_patient_session() -> Dict[str, Any]:
    """Sample patient session data for testing."""
    return {
        "patient_name": "John Doe",
        "patient_age": "45",
        "condition": "Lower back pain",
        "session_date": "2024-01-15",
        "subjective": "Patient reports lower back pain, 7/10 intensity, duration 3 days. Pain worsens with prolonged sitting and forward bending.",
        "objective": "Limited lumbar flexion (50% normal range), positive straight leg raise test at 60 degrees, tender L4-L5 region.",
        "assessment": "Acute lumbar strain with possible disc involvement. Functional limitations in ADLs.",
        "plan": "Continue manual therapy, home exercises program, postural education. Review in 1 week.",
        "exercises": [
            {"name": "Cat-cow exercises", "description": "10 repetitions, 3 times daily"},
            {"name": "Bridge exercises", "description": "Hold for 10 seconds, 10 repetitions, 2 times daily"}
        ]
    }


@pytest.fixture
def sample_exercise_search_results() -> List[Dict[str, Any]]:
    """Sample exercise search results for testing."""
    return [
        {
            "type": "image",
            "name": "Cat-cow exercise demonstration",
            "url": "https://example.com/cat-cow-1.jpg"
        },
        {
            "type": "image", 
            "name": "Cat-cow sequence illustration",
            "url": "https://example.com/cat-cow-2.jpg"
        }
    ]


@pytest.fixture
def mock_linkup_client():
    """Mock LinkupClient for testing."""
    with patch('motion.tools.exercise_illustration_tool.LinkupClient') as mock_client:
        mock_instance = Mock()
        mock_client.return_value = mock_instance
        
        # Default successful response
        mock_instance.search.return_value = {
            "results": [
                {
                    "type": "image",
                    "name": "Exercise demonstration",
                    "url": "https://example.com/exercise.jpg"
                }
            ]
        }
        
        yield mock_instance


@pytest.fixture
def mock_agent():
    """Mock Google ADK Agent for testing."""
    with patch('motion.agents.soap_agents.agent.Agent') as mock_agent_class:
        mock_agent_instance = Mock()
        mock_agent_class.return_value = mock_agent_instance
        
        # Default agent properties
        mock_agent_instance.name = "soap_agent"
        mock_agent_instance.model = "test-model"
        mock_agent_instance.description = "Test agent"
        
        yield mock_agent_instance


@pytest.fixture
def chat_message_json() -> str:
    """Sample chat message JSON."""
    return json.dumps({
        "type": "chat_message",
        "content": "Hello! I'm here to help with physiotherapy questions.",
        "timestamp": "2024-01-01T10:00:00Z"
    })


@pytest.fixture
def soap_draft_json() -> str:
    """Sample SOAP draft message JSON."""
    return json.dumps({
        "type": "soap_draft",
        "soap_report": {
            "patient_name": "John Doe",
            "patient_age": "45",
            "condition": "Lower back pain",
            "session_date": "2024-01-15",
            "subjective": "Patient reports lower back pain, 7/10 intensity...",
            "objective": "Limited lumbar flexion, positive SLR test...",
            "assessment": "Acute lumbar strain with possible disc involvement...",
            "plan": "Continue manual therapy, home exercises program...",
            "exercises": [
                {"name": "Cat-cow exercises", "description": "10 repetitions, 3 times daily"}
            ]
        },
        "timestamp": "2024-01-01T10:00:00Z"
    })


@pytest.fixture
def exercise_selection_json() -> str:
    """Sample exercise selection message JSON."""
    return json.dumps({
        "type": "exercise_selection",
        "exercises": [
            {
                "id": "exercise_1",
                "name": "Cat-cow exercises",
                "description": "10 repetitions, 3 times daily",
                "images": [
                    {
                        "id": "img_cat_cow_0",
                        "url": "https://example.com/cat-cow-1.jpg",
                        "name": "Cat-cow demonstration",
                        "selected": False
                    }
                ]
            }
        ],
        "requires_selection": True,
        "timestamp": "2024-01-01T10:00:00Z"
    })