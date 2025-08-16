# Ollama Provider Setup

This document explains how to set up and use the Ollama provider in Kavi.

## What is Ollama?

Ollama is a local AI model runner that allows you to run large language models (LLMs) on your own hardware. It provides a simple API for generating text completions and supports many popular models.

## Prerequisites

1. **Install Ollama**: Follow the official installation guide at [ollama.ai](https://ollama.ai)
2. **Pull a model**: Download a model you want to use, for example:
   ```bash
   ollama pull llama3.2
   ```

## Configuration

### 1. Enable Ollama Provider

1. Open the app settings
2. Go to the "Providers" section
3. Find the "Ollama" card and toggle it to enabled

### 2. Configure Ollama Settings

- **Base URL**: Defaults to `http://localhost:11434`. Change this if your Ollama instance is running on a different host or port.
- **Default Model**: Set to `llama3.2` by default. Change this to match a model you have pulled.
- **API Key**: Not required for local Ollama instances.

### 3. Select Ollama as Active Provider

In the settings, use the provider selector to choose "Ollama" as your active AI provider.

## Usage

Once configured, you can use Ollama just like any other AI provider in the app:

1. Start a new chat
2. Type your message
3. The app will send your request to your local Ollama instance
4. Responses will be generated using the selected model

## Troubleshooting

### Model Not Found Error

If you see an error like "Model llama3.2 not found", you need to pull the model first:

```bash
ollama pull llama3.2
```

### Connection Refused

If you get a connection error:

1. Make sure Ollama is running: `ollama serve`
2. Check that the base URL is correct in settings
3. Verify the port (default: 11434) is not blocked by firewall

### Slow Responses

- Ollama performance depends on your hardware
- Consider using smaller models for faster responses
- Ensure you have sufficient RAM and GPU memory

## Available Models

Some popular models you can use with Ollama:

- `llama3.2` - Meta's Llama 3.2 (default)
- `llama3.1` - Meta's Llama 3.1
- `mistral` - Mistral AI's 7B model
- `codellama` - Code-focused Llama variant
- `phi3` - Microsoft's Phi-3 model

To see all available models: `ollama list`

To pull a new model: `ollama pull <model-name>`

## Advanced Configuration

### Custom Models

You can add custom model names in the settings if you have models with different names or want to use specific model variants.

### Network Configuration

If running Ollama on a different machine:

1. Configure Ollama to listen on all interfaces: `OLLAMA_HOST=0.0.0.0 ollama serve`
2. Update the base URL in app settings to point to your Ollama server
3. Ensure network connectivity between the app and Ollama server

## Security Considerations

- Ollama runs locally, so your data stays on your machine
- No API keys or external services required
- Consider network security if running Ollama on a shared network