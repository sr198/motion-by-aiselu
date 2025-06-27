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
    """Message containing initial SOAP report draft in structured format."""
    
    def __init__(self, soap_report: Dict[str, Any]):
        super().__init__(
            MessageType.SOAP_DRAFT,
            soap_report=soap_report
        )


class ExerciseSelectionMessage(StructuredMessage):
    """Message prompting user to select exercise images for multiple exercises."""
    
    def __init__(self, exercises: List[Dict[str, Any]]):
        super().__init__(
            MessageType.EXERCISE_SELECTION,
            exercises=exercises,
            requires_selection=True
        )


class FinalReportMessage(StructuredMessage):
    """Message containing final SOAP report with selected images."""
    
    def __init__(self, soap_report: Dict[str, Any], selected_images: List[str]):
        super().__init__(
            MessageType.FINAL_REPORT,
            soap_report=soap_report,
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


def create_soap_draft_message(soap_report: Dict[str, Any]) -> str:
    """Helper function to create SOAP draft message JSON."""
    return SoapDraftMessage(soap_report).to_json()


def create_exercise_selection_message(exercises: List[Dict[str, Any]]) -> str:
    """Helper function to create exercise selection message JSON."""
    return ExerciseSelectionMessage(exercises).to_json()


def create_final_report_message(soap_report: Dict[str, Any], selected_images: List[str]) -> str:
    """Helper function to create final report message JSON."""
    return FinalReportMessage(soap_report, selected_images).to_json()


def create_clarification_message(questions: List[str], original_content: str) -> str:
    """Helper function to create clarification message JSON."""
    return ClarificationMessage(questions, original_content).to_json()


def create_error_message(error: str, details: Optional[str] = None) -> str:
    """Helper function to create error message JSON."""
    return ErrorMessage(error, details).to_json()


# Helper functions for creating structured SOAP data

def create_soap_item(item_type: str, content: str, emphasis: Optional[str] = None, sub_items: Optional[List[Dict[str, Any]]] = None) -> Dict[str, Any]:
    """Create a SOAP item with proper structure."""
    return {
        "type": item_type,
        "content": content,
        "emphasis": emphasis,
        "sub_items": sub_items
    }

def create_soap_section(title: str, items: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Create a SOAP section with proper structure."""
    return {
        "title": title,
        "items": items
    }

def create_patient_info(name: Optional[str] = None, age: Optional[str] = None, 
                       condition: Optional[str] = None, session_date: Optional[str] = None) -> Dict[str, Any]:
    """Create patient info structure."""
    return {
        "name": name,
        "age": age,
        "condition": condition,
        "session_date": session_date
    }

def create_soap_report(patient_info: Optional[Dict[str, Any]], subjective: Dict[str, Any], 
                      objective: Dict[str, Any], assessment: Dict[str, Any], 
                      plan: Dict[str, Any], timestamp: str) -> Dict[str, Any]:
    """Create complete SOAP report structure."""
    return {
        "patient_info": patient_info,
        "subjective": subjective,
        "objective": objective,
        "assessment": assessment,
        "plan": plan,
        "timestamp": timestamp
    }

def create_exercise_with_images(exercise_id: str, name: str, description: str, 
                               search_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Create exercise structure with processed images."""
    processed_images = []
    for i, img in enumerate(search_results):
        processed_images.append({
            "id": f"img_{exercise_id}_{i}",
            "url": img.get("url", ""),
            "name": img.get("name", f"{name} illustration {i+1}"),
            "selected": False
        })
    
    return {
        "id": exercise_id,
        "name": name,
        "description": description,
        "images": processed_images
    }