"""
Message type definitions for structured frontend communication.
"""

from enum import Enum
from typing import List, Dict, Any, Optional
from datetime import datetime
import json


class MessageType(str, Enum):
    """Enumeration of message types for frontend rendering."""
    CHAT_MESSAGE = "chat_message"
    SOAP_DRAFT = "soap_draft"
    EXERCISE_SELECTION = "exercise_selection"
    FINAL_REPORT = "final_report"
    CLARIFICATION = "clarification_needed"
    ERROR = "error"


class StructuredMessage:
    """Base class for structured messages to frontend."""
    
    def __init__(self, message_type: MessageType, **kwargs):
        self.type = message_type
        self.timestamp = datetime.now().isoformat()
        self.data = kwargs
    
    def to_json(self) -> str:
        """Convert message to JSON string for transmission."""
        return json.dumps({
            "type": self.type,
            "timestamp": self.timestamp,
            **self.data
        }, indent=2)


class ChatMessage(StructuredMessage):
    """Message containing general chat response."""
    
    def __init__(self, content: str):
        super().__init__(
            MessageType.CHAT_MESSAGE,
            content=content
        )


class SoapDraftMessage(StructuredMessage):
    """Message containing initial SOAP report draft without images."""
    
    def __init__(self, content: str, format: str = "markdown"):
        super().__init__(
            MessageType.SOAP_DRAFT,
            content=content,
            format=format
        )


class ExerciseSelectionMessage(StructuredMessage):
    """Message prompting user to select exercise images."""
    
    def __init__(self, exercise_name: str, exercise_description: str, images: List[Dict[str, Any]]):
        # Add selection state and IDs to images
        processed_images = []
        for i, img in enumerate(images):
            processed_images.append({
                "id": f"img_{exercise_name.replace(' ', '_').lower()}_{i}",
                "url": img.get("url", ""),
                "name": img.get("name", f"Exercise illustration {i+1}"),
                "selected": False
            })
        
        super().__init__(
            MessageType.EXERCISE_SELECTION,
            exercise_name=exercise_name,
            exercise_description=exercise_description,
            images=processed_images,
            requires_selection=True
        )


class FinalReportMessage(StructuredMessage):
    """Message containing final SOAP report with selected images."""
    
    def __init__(self, content: str, selected_images: List[str], format: str = "markdown"):
        super().__init__(
            MessageType.FINAL_REPORT,
            content=content,
            format=format,
            selected_images=selected_images,
            ready_for_pdf=True
        )


class ClarificationMessage(StructuredMessage):
    """Message requesting clarification from user."""
    
    def __init__(self, questions: List[str], original_content: str):
        super().__init__(
            MessageType.CLARIFICATION,
            questions=questions,
            original_content=original_content
        )


class ErrorMessage(StructuredMessage):
    """Message indicating an error occurred."""
    
    def __init__(self, error: str, details: Optional[str] = None):
        super().__init__(
            MessageType.ERROR,
            error=error,
            details=details
        )


def create_chat_message(content: str) -> str:
    """Helper function to create chat message JSON."""
    return ChatMessage(content).to_json()


def create_soap_draft_message(content: str) -> str:
    """Helper function to create SOAP draft message JSON."""
    return SoapDraftMessage(content).to_json()


def create_exercise_selection_message(exercise_name: str, exercise_description: str, images: List[Dict[str, Any]]) -> str:
    """Helper function to create exercise selection message JSON."""
    return ExerciseSelectionMessage(exercise_name, exercise_description, images).to_json()


def create_final_report_message(content: str, selected_images: List[str]) -> str:
    """Helper function to create final report message JSON."""
    return FinalReportMessage(content, selected_images).to_json()


def create_clarification_message(questions: List[str], original_content: str) -> str:
    """Helper function to create clarification message JSON."""
    return ClarificationMessage(questions, original_content).to_json()


def create_error_message(error: str, details: Optional[str] = None) -> str:
    """Helper function to create error message JSON."""
    return ErrorMessage(error, details).to_json()