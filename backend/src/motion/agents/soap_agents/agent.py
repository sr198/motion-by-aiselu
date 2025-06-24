import os
from load_dotenv import load_dotenv

from google.adk.agents import Agent

from motion.agents.soap_agents.prompts import INSTRUCTION
from motion.tools.exercise_illustration_tool import search_exercise_illustrations

load_dotenv()

root_agent = Agent(
    name="soap_agent",
    model= os.environ['MODEL_GEMINI_2_0_FLASH'],
    description="The main orchestrating agent that generates the SOAP report from the provided transcription and enhances it with exercise illustrations.",
    instruction= INSTRUCTION,
    tools=[search_exercise_illustrations],
)