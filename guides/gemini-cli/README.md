# Gemini CLI Guide

Complete guide to using Google's Gemini CLI for AI-assisted development in the terminal.

---

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Basic Usage](#basic-usage)
- [Advanced Features](#advanced-features)
- [Multimodal Capabilities](#multimodal-capabilities)
- [Integration Patterns](#integration-patterns)
- [Best Practices](#best-practices)
- [Comparison](#comparison)
- [Troubleshooting](#troubleshooting)

---

## Overview

Gemini CLI provides command-line access to Google's Gemini AI models, offering powerful capabilities for development tasks directly in your terminal.

### Key Features

- ✅ **Large Context Window** - Up to 2M tokens (largest available)
- ✅ **Multimodal Support** - Text, images, audio, video
- ✅ **Multiple Models** - Gemini Pro, Ultra, Flash
- ✅ **Command-Line Native** - Built for terminal workflows
- ✅ **Google Integration** - Access to Google services
- ✅ **Streaming Responses** - Real-time output
- ✅ **Function Calling** - Execute tools and commands

### When to Use Gemini CLI

**Best for:**
- Very large codebases requiring extensive context
- Multimodal tasks (analyzing images, diagrams, videos)
- Complex analysis and reasoning tasks
- Integration with Google Cloud services
- Projects already using Google ecosystem

**Not ideal for:**
- Real-time code completion (use Copilot)
- Multi-agent orchestration (use Claude Code)
- IDE-integrated workflows (use Copilot)

---

## Installation

### Prerequisites

- Python 3.7+
- Google Cloud account
- API key or service account credentials

### Install via pip

```bash
pip install google-generativeai
```

### Alternative: Install from source

```bash
git clone https://github.com/google/generative-ai-python.git
cd generative-ai-python
pip install -e .
```

### Set Up API Key

1. **Get API key** from [Google AI Studio](https://makersuite.google.com/app/apikey)

2. **Set environment variable**:
   ```bash
   export GOOGLE_API_KEY='your-api-key-here'
   ```

3. **Add to shell profile** for persistence:
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   echo 'export GOOGLE_API_KEY="your-api-key-here"' >> ~/.bashrc
   source ~/.bashrc
   ```

### Verify Installation

```bash
python -c "import google.generativeai as genai; print('Gemini installed successfully')"
```

---

## Getting Started

### Basic Python Script

Create a simple CLI wrapper:

```python
#!/usr/bin/env python3
import google.generativeai as genai
import os
import sys

# Configure API key
genai.configure(api_key=os.environ['GOOGLE_API_KEY'])

# Initialize model
model = genai.GenerativeModel('gemini-pro')

# Get prompt from command line
prompt = ' '.join(sys.argv[1:])

# Generate response
response = model.generate_content(prompt)
print(response.text)
```

Save as `gemini` and make executable:
```bash
chmod +x gemini
./gemini "Explain async/await in Python"
```

### Interactive Mode

```python
#!/usr/bin/env python3
import google.generativeai as genai
import os

genai.configure(api_key=os.environ['GOOGLE_API_KEY'])
model = genai.GenerativeModel('gemini-pro')
chat = model.start_chat(history=[])

print("Gemini CLI (type 'exit' to quit)")
while True:
    user_input = input("\nYou: ")
    if user_input.lower() == 'exit':
        break

    response = chat.send_message(user_input)
    print(f"\nGemini: {response.text}")
```

---

## Basic Usage

### Simple Queries

```bash
# Ask questions
gemini "How do I implement a binary search tree in Python?"

# Code generation
gemini "Write a Flask API endpoint for user authentication"

# Code explanation
gemini "Explain this code: $(cat script.py)"

# Debugging help
gemini "Why am I getting this error: TypeError: 'NoneType' object is not iterable"
```

### With File Input

```python
import google.generativeai as genai

# Read file
with open('code.py', 'r') as f:
    code = f.read()

# Analyze
model = genai.GenerativeModel('gemini-pro')
response = model.generate_content(f"Review this code for bugs:\n\n{code}")
print(response.text)
```

### Streaming Responses

```python
model = genai.GenerativeModel('gemini-pro')

# Stream response for long outputs
response = model.generate_content("Explain Kubernetes architecture", stream=True)

for chunk in response:
    print(chunk.text, end='', flush=True)
```

---

## Advanced Features

### Model Selection

**Available Models:**

```python
# Gemini Pro - Balanced performance
model = genai.GenerativeModel('gemini-pro')

# Gemini Pro Vision - Multimodal (images)
model = genai.GenerativeModel('gemini-pro-vision')

# Gemini Ultra - Most capable (when available)
model = genai.GenerativeModel('gemini-ultra')

# Gemini Flash - Fastest, optimized for speed
model = genai.GenerativeModel('gemini-1.5-flash')
```

### Configuration Options

```python
generation_config = {
    "temperature": 0.7,        # Creativity (0-1)
    "top_p": 0.95,             # Nucleus sampling
    "top_k": 40,               # Top-k sampling
    "max_output_tokens": 2048, # Response length
    "stop_sequences": ["END"], # Stop generation
}

model = genai.GenerativeModel(
    'gemini-pro',
    generation_config=generation_config
)
```

### Safety Settings

```python
safety_settings = [
    {
        "category": "HARM_CATEGORY_HARASSMENT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
    },
    {
        "category": "HARM_CATEGORY_HATE_SPEECH",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
    },
]

model = genai.GenerativeModel(
    'gemini-pro',
    safety_settings=safety_settings
)
```

### Chat Sessions

```python
model = genai.GenerativeModel('gemini-pro')
chat = model.start_chat(history=[])

# Multi-turn conversation
response1 = chat.send_message("What is a closure in JavaScript?")
print(response1.text)

response2 = chat.send_message("Can you show me an example?")
print(response2.text)

# Access history
for message in chat.history:
    print(f"{message.role}: {message.parts[0].text[:50]}...")
```

### Function Calling

```python
import google.generativeai as genai

# Define functions
functions = [
    {
        "name": "execute_command",
        "description": "Execute a shell command",
        "parameters": {
            "type": "object",
            "properties": {
                "command": {
                    "type": "string",
                    "description": "The shell command to execute"
                }
            },
            "required": ["command"]
        }
    }
]

model = genai.GenerativeModel('gemini-pro', tools=functions)

# Model can now call functions
response = model.generate_content("List files in current directory")
```

---

## Multimodal Capabilities

### Working with Images

```python
import PIL.Image
import google.generativeai as genai

# Load image
image = PIL.Image.open('diagram.png')

# Use vision model
model = genai.GenerativeModel('gemini-pro-vision')

# Analyze image
response = model.generate_content([
    "Explain what this diagram shows",
    image
])
print(response.text)
```

### Screenshot Analysis

```bash
# Take screenshot and analyze
import pyautogui
import google.generativeai as genai

screenshot = pyautogui.screenshot()
model = genai.GenerativeModel('gemini-pro-vision')

response = model.generate_content([
    "What UI elements are visible in this screenshot?",
    screenshot
])
print(response.text)
```

### Code Diagram Understanding

```python
# Analyze architecture diagrams
image = PIL.Image.open('architecture.png')
model = genai.GenerativeModel('gemini-pro-vision')

response = model.generate_content([
    "Convert this architecture diagram into a detailed written description. Include all components, connections, and data flows.",
    image
])
```

### Video Analysis

```python
# Upload and analyze video
import google.generativeai as genai

# Upload video file
video_file = genai.upload_file('demo.mp4')

# Analyze with Gemini
model = genai.GenerativeModel('gemini-pro-vision')
response = model.generate_content([
    "Summarize what happens in this video",
    video_file
])
print(response.text)
```

---

## Integration Patterns

### CLI Wrapper Script

```python
#!/usr/bin/env python3
"""
Gemini CLI - Command-line interface for Google Gemini
Usage: gemini [options] <prompt>
"""
import argparse
import google.generativeai as genai
import os
import sys

def main():
    parser = argparse.ArgumentParser(description='Gemini CLI')
    parser.add_argument('prompt', nargs='+', help='Prompt for Gemini')
    parser.add_argument('-m', '--model', default='gemini-pro',
                       help='Model to use (default: gemini-pro)')
    parser.add_argument('-t', '--temperature', type=float, default=0.7,
                       help='Temperature (0-1)')
    parser.add_argument('-f', '--file', help='Input file path')
    parser.add_argument('-i', '--image', help='Image file path')
    parser.add_argument('-s', '--stream', action='store_true',
                       help='Stream response')

    args = parser.parse_args()

    # Configure
    genai.configure(api_key=os.environ['GOOGLE_API_KEY'])

    # Build prompt
    prompt = ' '.join(args.prompt)

    if args.file:
        with open(args.file, 'r') as f:
            prompt += f"\n\nFile content:\n{f.read()}"

    # Generate
    model = genai.GenerativeModel(args.model)

    content = [prompt]
    if args.image:
        import PIL.Image
        content.append(PIL.Image.open(args.image))

    if args.stream:
        response = model.generate_content(content, stream=True)
        for chunk in response:
            print(chunk.text, end='', flush=True)
        print()
    else:
        response = model.generate_content(content)
        print(response.text)

if __name__ == '__main__':
    main()
```

### Git Integration

```bash
#!/bin/bash
# gemini-commit: Generate commit message

# Get staged changes
DIFF=$(git diff --staged)

# Generate commit message
python3 << EOF
import google.generativeai as genai
import os

genai.configure(api_key=os.environ['GOOGLE_API_KEY'])
model = genai.GenerativeModel('gemini-pro')

diff = """$DIFF"""
response = model.generate_content(f"Generate a concise commit message for these changes:\n\n{diff}")
print(response.text)
EOF
```

### Code Review Helper

```python
#!/usr/bin/env python3
import google.generativeai as genai
import subprocess
import os

genai.configure(api_key=os.environ['GOOGLE_API_KEY'])
model = genai.GenerativeModel('gemini-pro')

# Get PR diff
diff = subprocess.check_output(['git', 'diff', 'main...HEAD']).decode()

# Review
prompt = f"""
Review this pull request for:
- Code quality issues
- Potential bugs
- Security vulnerabilities
- Best practices violations

{diff}
"""

response = model.generate_content(prompt)
print(response.text)
```

### Documentation Generation

```python
#!/usr/bin/env python3
import google.generativeai as genai
import os
import glob

genai.configure(api_key=os.environ['GOOGLE_API_KEY'])
model = genai.GenerativeModel('gemini-pro')

# Read all Python files
files = glob.glob('**/*.py', recursive=True)
code = {}
for file in files:
    with open(file) as f:
        code[file] = f.read()

# Generate documentation
prompt = f"""
Generate comprehensive API documentation for this Python project.
Include:
- Module overview
- Class and function documentation
- Usage examples

Code files:
{chr(10).join([f'{k}:{chr(10)}{v}' for k,v in code.items()])}
"""

response = model.generate_content(prompt)

# Save documentation
with open('API.md', 'w') as f:
    f.write(response.text)

print("Documentation generated: API.md")
```

---

## Best Practices

### Optimize for Large Context

```python
# Use Gemini's large context effectively
with open('large_codebase.txt', 'r') as f:
    codebase = f.read()  # Can be up to 2M tokens

model = genai.GenerativeModel('gemini-pro')

# Ask specific questions about large context
response = model.generate_content(f"""
Analyze this entire codebase and identify:
1. All database query patterns
2. Potential N+1 query issues
3. Missing indexes

Codebase:
{codebase}
""")
```

### Structured Output

```python
# Request JSON output for programmatic use
response = model.generate_content("""
Analyze this code and return JSON with this structure:
{
  "bugs": [...],
  "security_issues": [...],
  "improvements": [...]
}

Code: ...
""")

import json
result = json.loads(response.text)
```

### Error Handling

```python
import google.generativeai as genai
from google.api_core import exceptions

try:
    model = genai.GenerativeModel('gemini-pro')
    response = model.generate_content(prompt)
    print(response.text)
except exceptions.ResourceExhausted:
    print("Rate limit exceeded. Please try again later.")
except exceptions.InvalidArgument as e:
    print(f"Invalid request: {e}")
except Exception as e:
    print(f"Error: {e}")
```

### Cost Optimization

```python
# Use appropriate model for task
# Flash for simple tasks (cheaper, faster)
model_fast = genai.GenerativeModel('gemini-1.5-flash')

# Pro for complex reasoning
model_pro = genai.GenerativeModel('gemini-pro')

# Choose based on task
if task_is_simple:
    response = model_fast.generate_content(prompt)
else:
    response = model_pro.generate_content(prompt)
```

---

## Comparison with Other Tools

### vs Claude Code

**Gemini CLI Advantages:**
- 2M token context (vs 200K)
- Multimodal capabilities
- Faster for simple queries
- Google ecosystem integration

**Claude Code Advantages:**
- MCP server ecosystem
- Multi-agent orchestration
- Better for complex workflows
- More development-focused

### vs GitHub Copilot

**Gemini CLI Advantages:**
- Large context window
- Multimodal support
- Complex reasoning
- Conversational

**Copilot Advantages:**
- Real-time completions
- IDE integration
- GitHub workflow integration
- Code-specific training

### Combined Usage

```bash
# Use Gemini for analysis
gemini "Analyze this 50k line codebase for patterns" > analysis.md

# Use Copilot for implementation
# (in IDE while writing code)

# Use Claude Code for orchestration
# (multi-phase refactoring project)
```

---

## Troubleshooting

### API Key Issues

```bash
# Verify API key is set
echo $GOOGLE_API_KEY

# Test API key
python -c "import google.generativeai as genai; genai.configure(api_key='$GOOGLE_API_KEY'); print('API key valid')"
```

### Rate Limiting

```python
import time
from google.api_core import exceptions

def generate_with_retry(model, prompt, max_retries=3):
    for attempt in range(max_retries):
        try:
            return model.generate_content(prompt)
        except exceptions.ResourceExhausted:
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt  # Exponential backoff
                print(f"Rate limited. Waiting {wait_time}s...")
                time.sleep(wait_time)
            else:
                raise
```

### Context Length Errors

```python
# Check token count before sending
model = genai.GenerativeModel('gemini-pro')

# Count tokens
token_count = model.count_tokens(prompt)
print(f"Tokens: {token_count}")

# Split if too large
MAX_TOKENS = 1900000  # Leave margin
if token_count > MAX_TOKENS:
    # Split prompt into chunks
    # Process separately
    pass
```

---

## Resources

- **Official Docs**: https://ai.google.dev/docs
- **API Reference**: https://ai.google.dev/api/python/google/generativeai
- **Python SDK**: https://github.com/google/generative-ai-python
- **Examples**: https://github.com/google/generative-ai-docs
- **Pricing**: https://ai.google.dev/pricing

---

## Next Steps

1. [Install Gemini CLI](#installation)
2. [Try basic examples](#getting-started)
3. [Explore multimodal features](#multimodal-capabilities)
4. [Compare with other tools](../../comparisons/feature-matrix.md)
5. [Join the community](../../SUPPORT.md)

---

**Last Updated**: 2025-11-04
