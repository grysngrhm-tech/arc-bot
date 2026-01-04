# Voice Mode Setup Guide

This guide explains how to set up the n8n workflow for ARC Bot's voice mode feature using OpenAI's Realtime API.

## Quick Start

The **ARC Bot - Voice Session** workflow has been created in n8n (ID: `eNkvTZbFPjbkQIz2`).

**To enable voice mode:**
1. Open n8n at https://n8n.srv1208741.hstgr.cloud
2. Go to Workflows → "ARC Bot - Voice Session"
3. Click the toggle to **Activate** the workflow
4. The webhook will be live at: `https://n8n.srv1208741.hstgr.cloud/webhook/arc-voice-session`

## Overview

Voice mode uses OpenAI's Realtime API for natural, low-latency voice conversations. The frontend connects directly to OpenAI via WebRTC, but needs an ephemeral token from your backend to authenticate securely.

## Architecture

```
User → Frontend → n8n (get token) → OpenAI (create session)
                ↓
        Frontend ←→ OpenAI Realtime API (WebRTC)
                ↓
        Frontend → n8n (RAG search) → Supabase
```

## n8n Workflow: Voice Session Endpoint

### Webhook Configuration

Create a new workflow with a **Webhook** node:

- **HTTP Method**: POST
- **Path**: `arc-voice-session`
- **Authentication**: None (or add your own)
- **Response Mode**: Last Node

### HTTP Request Node: Create Ephemeral Token

Add an **HTTP Request** node with:

**Settings:**
- **Method**: POST
- **URL**: `https://api.openai.com/v1/realtime/sessions`

**Headers:**
```
Authorization: Bearer {{ $env.OPENAI_API_KEY }}
Content-Type: application/json
```

**Body (JSON):**
```json
{
  "model": "gpt-4o-realtime-preview-2024-12-17",
  "voice": "alloy"
}
```

### Response

The workflow should return the OpenAI response directly, which includes:

```json
{
  "id": "sess_...",
  "object": "realtime.session",
  "model": "gpt-4o-realtime-preview-2024-12-17",
  "modalities": ["audio", "text"],
  "client_secret": {
    "value": "ek_...",
    "expires_at": 1234567890
  }
}
```

The frontend uses `client_secret.value` to authenticate the WebRTC connection.

## Complete Workflow JSON

Import this into n8n:

```json
{
  "name": "ARC Voice Session",
  "nodes": [
    {
      "parameters": {
        "httpMethod": "POST",
        "path": "arc-voice-session",
        "responseMode": "lastNode",
        "options": {
          "responseHeaders": {
            "entries": [
              {
                "name": "Access-Control-Allow-Origin",
                "value": "*"
              }
            ]
          }
        }
      },
      "id": "webhook",
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 2,
      "position": [250, 300]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "https://api.openai.com/v1/realtime/sessions",
        "authentication": "predefinedCredentialType",
        "nodeCredentialType": "openAiApi",
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ]
        },
        "sendBody": true,
        "specifyBody": "json",
        "jsonBody": "{\n  \"model\": \"gpt-4o-realtime-preview-2024-12-17\",\n  \"voice\": \"alloy\"\n}",
        "options": {}
      },
      "id": "http-request",
      "name": "Create Realtime Session",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.2,
      "position": [470, 300],
      "credentials": {
        "openAiApi": {
          "id": "YOUR_CREDENTIAL_ID",
          "name": "OpenAI API"
        }
      }
    }
  ],
  "connections": {
    "Webhook": {
      "main": [
        [
          {
            "node": "Create Realtime Session",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
```

## Voice Options

Available voices for the Realtime API:
- `alloy` - Neutral, balanced
- `echo` - Warm, conversational  
- `shimmer` - Clear, expressive
- `ash` - Calm, measured
- `ballad` - Warm, engaging
- `coral` - Clear, friendly
- `sage` - Wise, thoughtful
- `verse` - Dynamic, versatile

## Cost Considerations

OpenAI Realtime API pricing (as of 2024):
- **Audio input**: $0.06 per minute
- **Audio output**: $0.24 per minute
- **Text tokens**: Same as GPT-4o

A typical 30-second question + 30-second response costs approximately $0.06-0.15.

## Security Notes

1. **Never expose your OpenAI API key** in the frontend
2. The ephemeral token expires in 60 seconds
3. Consider adding rate limiting to the voice session endpoint
4. Add authentication if deploying to production

## Troubleshooting

### "Failed to get voice session token"
- Check that your n8n workflow is active
- Verify the webhook URL matches `VOICE_API_URL` in index.html
- Check n8n logs for errors

### "Microphone permission denied"
- User must allow microphone access in browser
- HTTPS is required for microphone access (except localhost)

### WebRTC connection fails
- Ensure the ephemeral token hasn't expired (60s lifetime)
- Check browser console for detailed errors
- Verify CORS headers are set correctly

### No audio playback
- Check that the browser isn't blocking autoplay
- Verify audio element has correct srcObject
- Check browser audio permissions

## Testing

1. Deploy the n8n workflow
2. Test the webhook directly:
   ```bash
   curl -X POST https://your-n8n-domain/webhook/arc-voice-session
   ```
3. Verify you receive a response with `client_secret`
4. Open ARC Bot and tap the microphone button
5. Allow microphone access when prompted
6. Speak a question and verify the response

