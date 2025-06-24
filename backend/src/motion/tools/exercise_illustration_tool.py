"""
Exercise illustration search tool using Linkup AI Search API.
"""

import os
import json
from typing import Dict, Any

from linkup import LinkupClient


# Structured output schema for image search results
LINKUP_IMAGE_SEARCH_SCHEMA = {
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "SearchResults",
    "type": "object",
    "required": ["results"],
    "properties": {
        "results": {
            "type": "array",
            "items": {
                "type": "object",
                "required": ["type", "name", "url"],
                "properties": {
                    "type": {
                        "type": "string",
                        "enum": ["image"]
                    },
                    "name": {
                        "type": "string",
                        "minLength": 1
                    },
                    "url": {
                        "type": "string",
                        "format": "uri"
                    }
                },
                "additionalProperties": False
            }
        }
    },
    "additionalProperties": False
}

def search_exercise_illustrations(exercise_name: str) -> Dict[str, Any]:
    """
    Search for illustration images of a specific physiotherapy exercise using Linkup AI Search.
    
    Args:
        exercise_name: The name of the exercise to search for (e.g., "Seated Banded L Ankle Dorsiflexion")
        
    Returns:
        Dictionary containing search results with exercise illustration images
    """
    # Initialize Linkup client
    api_key = os.getenv("LINKUP_API_KEY")
    if not api_key:
        return {
            "error": "LINKUP_API_KEY environment variable is not set",
            "exercise_name": exercise_name,
            "results": []
        }
    
    client = LinkupClient(api_key=api_key)
    
    try:
        query = f"Return me actual illustration images for the following physiotherapy exercise - {exercise_name}"
        
        response = client.search(
            query=query,
            depth="standard",
            output_type="structured",
            structured_output_schema=json.dumps(LINKUP_IMAGE_SEARCH_SCHEMA),
            include_images=True
        )
        
        return {
            "exercise_name": exercise_name,
            "search_query": query,
            "results": response.get("results", []) if response else []
        }
        
    except Exception as e:
        return {
            "error": f"Error searching for {exercise_name}: {str(e)}",
            "exercise_name": exercise_name,
            "results": []
        }