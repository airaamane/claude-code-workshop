---
name: a365-observability
description: Enhance Claude Agent SDK projects with Microsoft Agent 365 enterprise observability (OpenTelemetry tracing, audit logs, compliance). Use when adding telemetry, audit logs, or observability to Claude agents.
---

# Add Agent 365 Observability

This skill adds **Microsoft Agent 365 SDK observability** to existing Claude Agent SDK projects, providing enterprise-grade telemetry, audit logs, and compliance tracking via OpenTelemetry.

## What This Skill Does

Instruments your Claude agent with:
- ✅ Full inference tracking (inputs, outputs, tokens, errors)
- ✅ OpenTelemetry spans with structured metadata
- ✅ Agent identity and tenant context
- ✅ Conversation and session tracking
- ✅ Console validation for local testing
- ✅ Enterprise audit logs for compliance

## Prerequisites Check

Before proceeding, verify:

1. **Project Type**: This is a Node.js project with Claude Agent SDK
2. **Node.js Version**: 18.x or higher (`node --version`)
3. **Package Manager**: npm or yarn installed
4. **Existing Agent**: There's an agent implementation file (e.g., `src/agent.ts` or `src/index.ts`)

Run these checks:
```bash
# Verify Node.js version
node --version

# Check for Claude Agent SDK
npm list @anthropic-ai/sdk 2>/dev/null || echo "Claude SDK not found"

# Identify main agent file
ls src/agent.ts src/index.ts src/main.ts 2>/dev/null | head -n1
```

## Step 1: Install Observability Packages

Install the required Agent 365 observability dependencies:

```bash
npm install @microsoft/agents-a365-observability @microsoft/agents-a365-runtime
```

Verify installation:
```bash
npm list @microsoft/agents-a365-observability
```

## Step 2: Create Observability Configuration Module

Create `src/observability.ts` with the ObservabilityManager setup:

```typescript
// src/observability.ts
import { ObservabilityManager } from '@microsoft/agents-a365-observability';

/**
 * Token resolver for Agent 365 observability authentication.
 * In production, this should fetch tokens from your auth provider.
 * For local development, return a placeholder.
 */
const tokenResolver = (agentId: string, tenantId: string): string => {
  // TODO: Implement your token resolution logic
  // Example: return cachedTokens.get(`${agentId}:${tenantId}`);
  console.log(`[Observability] Token requested for agent=${agentId}, tenant=${tenantId}`);
  return 'dev-token-placeholder';
};

/**
 * Initialize and configure the Agent 365 Observability SDK.
 * Call this once at application startup.
 */
export function initializeObservability(serviceName: string, version: string = '1.0.0') {
  const builder = ObservabilityManager.configure((b) =>
    b
      .withService(serviceName, version)
      .withTokenResolver(tokenResolver)
  );

  builder.start();

  console.log(`[Observability] Initialized for service="${serviceName}" version="${version}"`);
  console.log(`[Observability] ENABLE_OBSERVABILITY=${process.env.ENABLE_OBSERVABILITY}`);
  console.log(`[Observability] ENABLE_A365_OBSERVABILITY_EXPORTER=${process.env.ENABLE_A365_OBSERVABILITY_EXPORTER}`);

  return builder;
}
```

## Step 3: Create Instrumented Agent Wrapper

Create `src/instrumented-agent.ts` to wrap Claude invocations with InferenceScope:

```typescript
// src/instrumented-agent.ts
import { InferenceScope, InferenceOperationType } from '@microsoft/agents-a365-observability';

/**
 * Agent metadata for observability context
 */
export interface AgentMetadata {
  agentId: string;
  agentName: string;
  agentDescription?: string;
  agentBlueprintId?: string;
}

/**
 * Tenant context for multi-tenant scenarios
 */
export interface TenantContext {
  tenantId: string;
}

/**
 * Conversation context for session tracking
 */
export interface ConversationContext {
  conversationId: string;
  sessionId?: string;
  channelName?: string;  // e.g., "msteams", "email", "api"
  clientIp?: string;
}

/**
 * Wraps a Claude agent invocation with Agent 365 observability instrumentation.
 *
 * @param agentFn - The async function that invokes your Claude agent
 * @param userMessage - The input message from the user
 * @param agentMetadata - Agent identity and metadata
 * @param tenantContext - Tenant information
 * @param conversationContext - Conversation and session details
 * @param modelName - Claude model identifier (e.g., "claude-3-5-sonnet-20241022")
 * @returns The agent's response with full observability tracing
 */
export async function invokeWithObservability<T>(
  agentFn: (message: string) => Promise<T>,
  userMessage: string,
  agentMetadata: AgentMetadata,
  tenantContext: TenantContext,
  conversationContext: ConversationContext,
  modelName: string = 'claude-3-5-sonnet-20241022'
): Promise<T> {

  // Create inference details for the scope
  const inferenceDetails = {
    operationName: InferenceOperationType.CHAT,
    model: modelName,
    providerName: 'anthropic',
    // Initial estimates - update after inference
    inputTokens: 0,
    outputTokens: 0,
    finishReasons: [] as string[],
    responseId: `resp-${Date.now()}`
  };

  // Create agent details
  const agentDetails = {
    agentId: agentMetadata.agentId,
    agentName: agentMetadata.agentName,
    agentDescription: agentMetadata.agentDescription,
    agentBlueprintId: agentMetadata.agentBlueprintId,
    conversationId: conversationContext.conversationId
  };

  // Create tenant details
  const tenantDetails = {
    tenantId: tenantContext.tenantId
  };

  // Start observability scope using 'using' for automatic disposal
  using scope = InferenceScope.start(inferenceDetails, agentDetails, tenantDetails);

  try {
    // Record input message
    scope.recordInputMessages([userMessage]);

    // Record channel and client info if available
    if (conversationContext.channelName) {
      // Channel name is recorded via baggage or span attributes
      console.log(`[Observability] Channel: ${conversationContext.channelName}`);
    }

    // Invoke the actual Claude agent
    const response = await agentFn(userMessage);

    // Extract response text (adjust based on your response structure)
    const responseText = typeof response === 'string' ? response : JSON.stringify(response);

    // Record output message
    scope.recordOutputMessages([responseText]);

    // Record token usage if available from response metadata
    // TODO: Extract actual token counts from Claude response
    // scope.recordInputTokens(actualInputTokens);
    // scope.recordOutputTokens(actualOutputTokens);

    // Record finish reason
    scope.recordFinishReasons(['stop']);

    // Record response ID if available
    // scope.recordResponseId(actualResponseId);

    return response;

  } catch (error) {
    // Record the error in observability
    scope.recordError(error as Error);

    console.error(`[Observability] Error in agent invocation:`, error);

    // Re-throw to maintain error handling flow
    throw error;
  }
  // Scope automatically disposed at end of 'using' block
}

/**
 * Helper to extract token counts from Claude response.
 * Implement based on your Claude SDK response structure.
 */
export function extractTokenCounts(response: any): { input: number; output: number } {
  // Example for Claude SDK response structure
  // Adjust based on actual response format
  return {
    input: response?.usage?.input_tokens || 0,
    output: response?.usage?.output_tokens || 0
  };
}
```

## Step 4: Integrate with Existing Agent

Now update your main agent file (e.g., `src/agent.ts` or `src/index.ts`) to use the observability wrapper:

**Before (Original Agent):**
```typescript
import Anthropic from '@anthropic-ai/sdk';

const client = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY
});

async function runAgent(userMessage: string) {
  const response = await client.messages.create({
    model: 'claude-3-5-sonnet-20241022',
    max_tokens: 1024,
    messages: [{ role: 'user', content: userMessage }]
  });

  return response.content[0].text;
}

// Usage
const result = await runAgent('Hello, Claude!');
```

**After (With Observability):**
```typescript
import Anthropic from '@anthropic-ai/sdk';
import { initializeObservability } from './observability';
import { invokeWithObservability } from './instrumented-agent';

// Initialize observability once at startup
initializeObservability('my-claude-agent', '1.0.0');

const client = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY
});

async function runAgent(userMessage: string) {
  const response = await client.messages.create({
    model: 'claude-3-5-sonnet-20241022',
    max_tokens: 1024,
    messages: [{ role: 'user', content: userMessage }]
  });

  return response.content[0].text;
}

// Wrap with observability
const result = await invokeWithObservability(
  runAgent,
  'Hello, Claude!',
  {
    agentId: 'agent-12345',
    agentName: 'My Claude Agent',
    agentDescription: 'Claude agent with enterprise observability'
  },
  {
    tenantId: 'tenant-67890'
  },
  {
    conversationId: 'conv-abc123',
    sessionId: 'session-xyz789',
    channelName: 'api',
    clientIp: '192.168.1.1'
  },
  'claude-3-5-sonnet-20241022'
);
```

## Step 5: Configure Environment Variables

Create or update `.env` file with observability settings:

```bash
# Claude API
ANTHROPIC_API_KEY=your-api-key-here

# Agent 365 Observability
ENABLE_OBSERVABILITY=true
ENABLE_A365_OBSERVABILITY_EXPORTER=false  # false = console output for local testing

# Agent Metadata (optional - can be passed programmatically)
AGENT_ID=agent-12345
AGENT_NAME=My Claude Agent
TENANT_ID=tenant-67890
```

## Step 6: Local Testing and Validation

Test the observability integration locally with console output:

```bash
# Run your agent
npm start

# OR if you have a test script
npm test
```

**Expected Console Output:**

You should see OpenTelemetry spans logged to console with this structure:

```json
{
  "name": "Chat claude-3-5-sonnet-20241022",
  "context": {
    "trace_id": "0xceb86559a6f7c2c16a45ec6e0b201ae1",
    "span_id": "0x475beec8c1c4fa56"
  },
  "attributes": {
    "gen_ai.operation.name": "Chat",
    "gen_ai.request.model": "claude-3-5-sonnet-20241022",
    "gen_ai.provider.name": "anthropic",
    "gen_ai.input.messages": "Hello, Claude!",
    "gen_ai.output.messages": "Hello! How can I help...",
    "gen_ai.usage.input_tokens": "33",
    "gen_ai.usage.output_tokens": "32",
    "gen_ai.agent.id": "agent-12345",
    "gen_ai.agent.name": "My Claude Agent",
    "tenant.id": "tenant-67890"
  }
}
```

## Step 7: Production Configuration

When ready for production:

1. **Enable Cloud Exporter:**
   ```bash
   ENABLE_A365_OBSERVABILITY_EXPORTER=true
   ```

2. **Implement Real Token Resolver:**
   Update `src/observability.ts` to fetch actual tokens from your auth provider:
   ```typescript
   const tokenResolver = async (agentId: string, tenantId: string): Promise<string> => {
     // Fetch from Azure AD / Entra
     const token = await fetchObservabilityToken(agentId, tenantId);
     return token;
   };
   ```

3. **Extract Real Token Counts:**
   Update `invokeWithObservability` to use actual token counts from Claude responses:
   ```typescript
   const { input, output } = extractTokenCounts(response);
   scope.recordInputTokens(input);
   scope.recordOutputTokens(output);
   ```

## Verification Checklist

- [ ] Packages installed: `@microsoft/agents-a365-observability`, `@microsoft/agents-a365-runtime`
- [ ] `src/observability.ts` created with ObservabilityManager config
- [ ] `src/instrumented-agent.ts` created with InferenceScope wrapper
- [ ] Main agent file updated to use `invokeWithObservability`
- [ ] `.env` configured with `ENABLE_OBSERVABILITY=true`
- [ ] Console output shows OpenTelemetry spans with correct metadata
- [ ] Input/output messages captured in spans
- [ ] Agent ID, tenant ID, and conversation ID present in spans
- [ ] Error handling tested (errors recorded in scopes)

## Troubleshooting

**Issue**: No console output for spans
- **Fix**: Ensure `ENABLE_OBSERVABILITY=true` and `ENABLE_A365_OBSERVABILITY_EXPORTER=false`

**Issue**: Missing token counts
- **Fix**: Implement `extractTokenCounts()` to parse Claude response usage metadata

**Issue**: TypeScript errors with 'using' keyword
- **Fix**: Ensure `tsconfig.json` has `"target": "ES2022"` or higher

**Issue**: Token resolver errors
- **Fix**: Return a placeholder string for local testing; implement real resolver for production

## Next Steps

Once observability is working:

1. **Add More Context**: Include session IDs, correlation IDs, and channel information
2. **Instrument Tools**: Add `ExecuteToolScope` for tool invocation tracking
3. **Agent-to-Agent**: Use `InvokeAgentScope` when calling other agents
4. **BaggageBuilder**: Set tenant/agent context globally for automatic propagation
5. **Production Deployment**: Switch to cloud exporter and implement real auth

## Learn More

- [Agent 365 Observability Docs](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/observability)
- [OpenTelemetry Specification](https://opentelemetry.io/docs/)
- [Claude Agent SDK](https://docs.anthropic.com/en/docs/agents)
