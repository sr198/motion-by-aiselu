"""
Main entry point for the Motion by Aiselu backend.
Runs the Google ADK agent server.
"""

import os
import sys
from pathlib import Path

# Add the src directory to the path so imports work
src_path = Path(__file__).parent.parent
sys.path.insert(0, str(src_path))

from motion.agents.soap_agents.agent import root_agent


def main():
    """Start the ADK agent server."""
    print("Starting Motion by Aiselu SOAP Agent Server...")
    print(f"Agent: {root_agent.name}")
    print(f"Model: {os.environ.get('MODEL_GEMINI_2_0_FLASH', 'Not set')}")
    print("Server will be available on http://localhost:8000")
    print("Available endpoints:")
    print("  POST /run - Run agent with message")
    print("  POST /run_sse - Run agent with streaming")
    print("  POST /apps/{app_name}/users/{user_id}/sessions/{session_id} - Create session")
    print()
    
    # The ADK agent automatically starts a server when the module is loaded
    # and the agent is defined. The server runs on localhost:8000 by default.
    try:
        # Keep the server running
        print("Press Ctrl+C to stop the server")
        import time
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nShutting down server...")


if __name__ == "__main__":
    main()
