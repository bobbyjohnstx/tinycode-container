---
name: configure-notifications
description: Configure notification integrations (Telegram, Discord, Slack) via natural language
triggers:
  - "configure notifications"
  - "setup notifications"
  - "configure telegram"
  - "setup telegram"
  - "telegram bot"
  - "configure discord"
  - "setup discord"
  - "discord webhook"
  - "configure slack"
  - "setup slack"
  - "slack webhook"
---

# Configure Notifications

Set up notification integrations so you're alerted when tinycode sessions end, need input, or complete background tasks.

> **Security note:** Bot tokens, webhook URLs, and API keys are written in plaintext to `notifications-config.json`. Add this file to `.gitignore` in any repo where it may be committed, and restrict file permissions (`chmod 600`) if the host is shared.

## When to Use

Use this skill when:
- The user says "configure notifications", "set up alerts", "notify me when the session finishes", or names a provider ("set up Telegram", "add Discord webhook", "Slack alerts")
- The user wants tinycode to send them a message on session-end, input-needed, or task-complete events
- The user wants to write a persistent notification integration to `notifications-config.json`

## When Not to Use

- The user wants to send a one-off notification right now — just run `curl` directly
- The user wants to configure a Slack/Discord/Telegram bot for non-tinycode application logic (deploy alerts, CI notifications, etc.)
- The user wants to add an MCP server — use the `mcp-setup` skill instead
- The user is configuring tinycode settings, hooks, or permissions — use the `update-config` skill

## Output Contract

On successful configuration, always report:
- **Provider configured** (Telegram / Discord / Slack)
- **Target** (chat ID, channel name, or webhook host)
- **Events enabled** (from Step 6 selection)
- **Config file path** written to
- **Test result** (HTTP 2xx confirmed / skipped by user / failed — include error if failed)

Do not print a "Configured!" message if the test failed and the user did not explicitly skip testing.

## Routing

Detect which provider the user wants based on their request or argument:
- If the trigger or argument contains "telegram" → follow the **Telegram** section
- If the trigger or argument contains "discord" → follow the **Discord** section
- If the trigger or argument contains "slack" → follow the **Slack** section
- If no provider is specified, use AskUserQuestion:

**Question:** "Which notification service would you like to configure?"

**Options:**
1. **Telegram** - Bot token + chat ID. Works on mobile and desktop.
2. **Discord** - Webhook or bot token + channel ID.
3. **Slack** - Incoming webhook URL.

---

## Telegram Setup

Set up Telegram notifications so tinycode can message you when sessions end, need input, or complete background tasks.

Config is written to `${TINYCODE_CONFIG_DIR:-~/.config/tinycode}/notifications-config.json`.

### Step 1: Detect Existing Configuration

```bash
CONFIG_FILE="${TINYCODE_CONFIG_DIR:-$HOME/.claude}/notifications-config.json"

if [ -f "$CONFIG_FILE" ]; then
  HAS_TELEGRAM=$(jq -r '.notifications.telegram.enabled // false' "$CONFIG_FILE" 2>/dev/null)
  CHAT_ID=$(jq -r '.notifications.telegram.chatId // empty' "$CONFIG_FILE" 2>/dev/null)
  PARSE_MODE=$(jq -r '.notifications.telegram.parseMode // "Markdown"' "$CONFIG_FILE" 2>/dev/null)

  if [ "$HAS_TELEGRAM" = "true" ]; then
    echo "EXISTING_CONFIG=true"
    echo "CHAT_ID=$CHAT_ID"
    echo "PARSE_MODE=$PARSE_MODE"
  else
    echo "EXISTING_CONFIG=false"
  fi
else
  echo "NO_CONFIG_FILE"
fi
```

If existing config is found, show the user what's currently configured and ask if they want to update or reconfigure.

### Step 2: Create a Telegram Bot

Guide the user through creating a bot if they don't have one:

```
To set up Telegram notifications, you need a Telegram bot token and your chat ID.

CREATE A BOT (if you don't have one):
1. Open Telegram and search for @BotFather
2. Send /newbot
3. Choose a name (e.g., "My tinycode Notifier")
4. Choose a username (e.g., "my_claude_bot")
5. BotFather will give you a token like: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz

GET YOUR CHAT ID:
1. Start a chat with your new bot (send /start)
2. Visit: https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates
3. Look for "chat":{"id":YOUR_CHAT_ID}
   - Personal chat IDs are positive numbers (e.g., 123456789)
   - Group chat IDs are negative numbers (e.g., -1001234567890)
```

### Step 3: Collect Bot Token

Use AskUserQuestion:

**Question:** "Paste your Telegram bot token (from @BotFather)"

The user will type their token in the "Other" field.

**Validate** the token:
- Must match pattern: `digits:alphanumeric` (e.g., `123456789:ABCdefGHI...`)
- If invalid, explain the format and ask again

### Step 4: Collect Chat ID

Use AskUserQuestion:

**Question:** "Paste your Telegram chat ID (the number from getUpdates API)"

The user will type their chat ID in the "Other" field.

**Validate** the chat ID:
- Must be a number (positive for personal, negative for groups)
- If invalid, offer to help them find it:

```bash
BOT_TOKEN="USER_PROVIDED_TOKEN"
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates" | jq '.result[-1].message.chat.id // .result[-1].message.from.id // "No messages found - send /start to your bot first"'
```

### Step 5: Choose Parse Mode

Use AskUserQuestion:

**Question:** "Which message format do you prefer?"

**Options:**
1. **Markdown (Recommended)** - Bold, italic, code blocks with Markdown syntax
2. **HTML** - Bold, italic, code with HTML tags

### Step 6: Configure Events

Use AskUserQuestion with multiSelect:

**Question:** "Which events should trigger Telegram notifications?"

**Options (multiSelect: true):**
1. **Session end (Recommended)** - When a tinycode session finishes
2. **Input needed** - When tinycode is waiting for your response
3. **Session start** - When a new session begins

### Step 7: Write Configuration

> **Note:** The model must substitute real collected values (BOT_TOKEN, CHAT_ID, etc.) into each bash block. Shell state does not persist between separate bash invocations — re-export or substitute variables explicitly in each block.

```bash
CONFIG_FILE="${TINYCODE_CONFIG_DIR:-$HOME/.claude}/notifications-config.json"
mkdir -p "$(dirname "$CONFIG_FILE")"

if [ -f "$CONFIG_FILE" ]; then
  EXISTING=$(cat "$CONFIG_FILE")
else
  EXISTING='{}'
fi

echo "$EXISTING" | jq \
  --arg token "$BOT_TOKEN" \
  --arg chatId "$CHAT_ID" \
  --arg parseMode "$PARSE_MODE" \
  '.notifications = (.notifications // {enabled: true}) |
   .notifications.enabled = true |
   .notifications.telegram = {
     enabled: true,
     botToken: $token,
     chatId: $chatId,
     parseMode: $parseMode
   }' > "$CONFIG_FILE"

# Model: substitute the user's Step 6 selection below (space-separated event names)
# Valid values: session-end  session-start  input-needed
SELECTED_EVENTS="session-end input-needed"  # <-- replace with actual selection

if [ -z "$SELECTED_EVENTS" ]; then
  echo "ERROR: SELECTED_EVENTS not set — cannot persist event preferences"
  exit 1
fi

CONFIG=$(cat "$CONFIG_FILE")
for event in "session-end" "session-start" "input-needed"; do
  if echo " $SELECTED_EVENTS " | grep -q " $event "; then
    STATE=true
  else
    STATE=false
  fi
  CONFIG=$(echo "$CONFIG" | jq --arg e "$event" --argjson s "$STATE" \
    '.notifications.events = (.notifications.events // {}) |
     .notifications.events[$e] = {enabled: $s}')
done
echo "$CONFIG" > "$CONFIG_FILE"
```

### Step 8: Test the Configuration

Use AskUserQuestion:

**Question:** "Send a test notification to verify the setup?"

**Options:**
1. **Yes, test now (Recommended)**
2. **No, I'll test later**

```bash
BOT_TOKEN="USER_PROVIDED_TOKEN"
CHAT_ID="USER_PROVIDED_CHAT_ID"
PARSE_MODE="Markdown"

RESPONSE=$(curl -s -w "\n%{http_code}" \
  "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -d "chat_id=${CHAT_ID}" \
  -d "parse_mode=${PARSE_MODE}" \
  -d "text=tinycode test notification - Telegram is configured!")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -1)

if [ "$HTTP_CODE" = "200" ]; then
  echo "Test notification sent successfully!"
else
  echo "Failed (HTTP $HTTP_CODE):"
  echo "$BODY" | jq -r '.description // "Unknown error"' 2>/dev/null || echo "$BODY"
fi
```

Common errors:
- **401 Unauthorized**: Bot token is invalid
- **400 Bad Request: chat not found**: Chat ID is wrong, or user hasn't sent `/start` to the bot

### Step 9: Confirm

Only print the "Configured!" confirmation if:
- The test notification returned HTTP 200, OR
- The user explicitly chose "No, I'll test later" (skip)

If the test failed, report the specific error and stop — do not print the success confirmation until the issue is resolved.

```
Telegram Notifications Configured!

  Chat ID:    123456789
  Format:     Markdown
  Events:     session-end, input-needed

Config saved to: ~/.config/tinycode/notifications-config.json

You can also set these via environment variables:
  TINYCODE_TELEGRAM_BOT_TOKEN=123456789:ABCdefGHI...
  TINYCODE_TELEGRAM_CHAT_ID=123456789
```

---

## Discord Setup

Set up Discord notifications so tinycode can ping you when sessions end, need input, or complete background tasks.

Config is written to `${TINYCODE_CONFIG_DIR:-~/.config/tinycode}/notifications-config.json`.

### Step 1: Detect Existing Configuration

```bash
CONFIG_FILE="${TINYCODE_CONFIG_DIR:-$HOME/.claude}/notifications-config.json"

if [ -f "$CONFIG_FILE" ]; then
  HAS_DISCORD=$(jq -r '.notifications.discord.enabled // false' "$CONFIG_FILE" 2>/dev/null)
  WEBHOOK_URL=$(jq -r '.notifications.discord.webhookUrl // empty' "$CONFIG_FILE" 2>/dev/null)
  if [ "$HAS_DISCORD" = "true" ]; then
    echo "EXISTING_CONFIG=true"
    [ -n "$WEBHOOK_URL" ] && echo "WEBHOOK_URL=$WEBHOOK_URL"
  else
    echo "EXISTING_CONFIG=false"
  fi
else
  echo "NO_CONFIG_FILE"
fi
```

### Step 2: Choose Discord Method

Use AskUserQuestion:

**Question:** "How would you like to send Discord notifications?"

**Options:**
1. **Webhook (Recommended)** - Create a webhook in your Discord channel. Simple, no bot needed.
2. **Bot API** - Use a Discord bot token + channel ID. More flexible, requires a bot application.

### Step 3A: Webhook Setup

Use AskUserQuestion:

**Question:** "Paste your Discord webhook URL. To create one: Server Settings > Integrations > Webhooks > New Webhook > Copy URL"

**Validate** the URL:
- Must start with `https://discord.com/api/webhooks/` or `https://discordapp.com/api/webhooks/`

### Step 3B: Bot API Setup

Ask two questions:
1. **"Paste your Discord bot token"** - From discord.com/developers > Your App > Bot > Token
2. **"Paste the channel ID"** - Right-click channel > Copy Channel ID (requires Developer Mode)

> **Note:** The Bot API path collects credentials for manual use. Automated session-event notifications (session-end, input-needed, etc.) require the webhook method — the write block in Step 6 only configures webhook delivery. If you choose Bot API, you will need to implement the delivery logic separately.

### Step 4: Configure Mention

Use AskUserQuestion:

**Question:** "Would you like notifications to mention (ping) someone?"

**Options:**
1. **Yes, mention a user** - Tag a specific user by their Discord user ID
2. **Yes, mention a role** - Tag a role by its role ID
3. **No mentions**

Mention format: `<@USER_ID>` for users, `<@&ROLE_ID>` for roles.

### Step 5: Configure Events

Use AskUserQuestion with multiSelect:

**Question:** "Which events should trigger Discord notifications?"

**Options (multiSelect: true):**
1. **Session end (Recommended)**
2. **Input needed**
3. **Session start**

### Step 6: Write Configuration

> **Note:** The model must substitute real collected values (WEBHOOK_URL, MENTION, etc.) into each bash block. Shell state does not persist between separate bash invocations — re-export or substitute variables explicitly in each block.

```bash
CONFIG_FILE="${TINYCODE_CONFIG_DIR:-$HOME/.claude}/notifications-config.json"
mkdir -p "$(dirname "$CONFIG_FILE")"

if [ -f "$CONFIG_FILE" ]; then
  EXISTING=$(cat "$CONFIG_FILE")
else
  EXISTING='{}'
fi

echo "$EXISTING" | jq \
  --arg url "$WEBHOOK_URL" \
  --arg mention "$MENTION" \
  '.notifications = (.notifications // {enabled: true}) |
   .notifications.enabled = true |
   .notifications.discord = {
     enabled: true,
     webhookUrl: $url,
     mention: (if $mention == "" then null else $mention end)
   }' > "$CONFIG_FILE"

# Model: substitute the user's Step 5 selection below (space-separated event names)
# Valid values: session-end  session-start  input-needed
SELECTED_EVENTS="session-end input-needed"  # <-- replace with actual selection

if [ -z "$SELECTED_EVENTS" ]; then
  echo "ERROR: SELECTED_EVENTS not set — cannot persist event preferences"
  exit 1
fi

CONFIG=$(cat "$CONFIG_FILE")
for event in "session-end" "session-start" "input-needed"; do
  if echo " $SELECTED_EVENTS " | grep -q " $event "; then
    STATE=true
  else
    STATE=false
  fi
  CONFIG=$(echo "$CONFIG" | jq --arg e "$event" --argjson s "$STATE" \
    '.notifications.events = (.notifications.events // {}) |
     .notifications.events[$e] = {enabled: $s}')
done
echo "$CONFIG" > "$CONFIG_FILE"
```

### Step 7: Test the Configuration

```bash
curl -s -o /dev/null -w "%{http_code}" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"${MENTION:+$MENTION\\n}tinycode test notification - Discord is configured!\"}" \
  "$WEBHOOK_URL"
```

### Step 8: Confirm

Only print the "Configured!" confirmation if:
- The test notification returned HTTP 204, OR
- The user explicitly chose "No, I'll test later" (skip)

If the test failed, report the specific error and stop — do not print the success confirmation until the issue is resolved.

```
Discord Notifications Configured!

  Method:   Webhook
  Mention:  <@1465264645320474637> (or "none")
  Events:   session-end, input-needed

Config saved to: ~/.config/tinycode/notifications-config.json
```

---

## Slack Setup

Set up Slack notifications so tinycode can message you when sessions end, need input, or complete background tasks.

Config is written to `${TINYCODE_CONFIG_DIR:-~/.config/tinycode}/notifications-config.json`.

### Step 1: Detect Existing Configuration

```bash
CONFIG_FILE="${TINYCODE_CONFIG_DIR:-$HOME/.claude}/notifications-config.json"

if [ -f "$CONFIG_FILE" ]; then
  HAS_SLACK=$(jq -r '.notifications.slack.enabled // false' "$CONFIG_FILE" 2>/dev/null)
  WEBHOOK_URL=$(jq -r '.notifications.slack.webhookUrl // empty' "$CONFIG_FILE" 2>/dev/null)
  if [ "$HAS_SLACK" = "true" ]; then
    echo "EXISTING_CONFIG=true"
    [ -n "$WEBHOOK_URL" ] && echo "WEBHOOK_URL=$WEBHOOK_URL"
  else
    echo "EXISTING_CONFIG=false"
  fi
else
  echo "NO_CONFIG_FILE"
fi
```

### Step 2: Create a Slack Incoming Webhook

Guide the user:

```
CREATE A WEBHOOK:
1. Go to https://api.slack.com/apps
2. Click "Create New App" > "From scratch"
3. Name your app (e.g., "tinycode Notifier") and select your workspace
4. Go to "Incoming Webhooks" in the left sidebar
5. Toggle "Activate Incoming Webhooks" to ON
6. Click "Add New Webhook to Workspace"
7. Select the channel where notifications should be posted
8. Copy the webhook URL (starts with https://hooks.slack.com/services/...)
```

### Step 3: Collect Webhook URL

Use AskUserQuestion:

**Question:** "Paste your Slack incoming webhook URL (starts with https://hooks.slack.com/services/...)"

**Validate:** Must start with `https://hooks.slack.com/services/`

### Step 4: Configure Mention

Use AskUserQuestion:

**Question:** "Would you like notifications to mention (ping) someone?"

**Options:**
1. **Yes, mention a user** - Tag a specific user by their Slack member ID
2. **Yes, mention @channel** - Notify everyone in the channel
3. **Yes, mention @here** - Notify only active members
4. **No mentions**

Mention formats: `<@MEMBER_ID>`, `<!channel>`, `<!here>`

### Step 5: Configure Events

Use AskUserQuestion with multiSelect:

**Question:** "Which events should trigger Slack notifications?"

**Options (multiSelect: true):**
1. **Session end (Recommended)**
2. **Input needed**
3. **Session start**

### Step 6: Write Configuration

> **Note:** The model must substitute real collected values (WEBHOOK_URL, MENTION, etc.) into each bash block. Shell state does not persist between separate bash invocations — re-export or substitute variables explicitly in each block.

```bash
CONFIG_FILE="${TINYCODE_CONFIG_DIR:-$HOME/.claude}/notifications-config.json"
mkdir -p "$(dirname "$CONFIG_FILE")"

if [ -f "$CONFIG_FILE" ]; then
  EXISTING=$(cat "$CONFIG_FILE")
else
  EXISTING='{}'
fi

echo "$EXISTING" | jq \
  --arg url "$WEBHOOK_URL" \
  --arg mention "$MENTION" \
  '.notifications = (.notifications // {enabled: true}) |
   .notifications.enabled = true |
   .notifications.slack = {
     enabled: true,
     webhookUrl: $url,
     mention: (if $mention == "" then null else $mention end)
   }' > "$CONFIG_FILE"

# Model: substitute the user's Step 5 selection below (space-separated event names)
# Valid values: session-end  session-start  input-needed
SELECTED_EVENTS="session-end input-needed"  # <-- replace with actual selection

if [ -z "$SELECTED_EVENTS" ]; then
  echo "ERROR: SELECTED_EVENTS not set — cannot persist event preferences"
  exit 1
fi

CONFIG=$(cat "$CONFIG_FILE")
for event in "session-end" "session-start" "input-needed"; do
  if echo " $SELECTED_EVENTS " | grep -q " $event "; then
    STATE=true
  else
    STATE=false
  fi
  CONFIG=$(echo "$CONFIG" | jq --arg e "$event" --argjson s "$STATE" \
    '.notifications.events = (.notifications.events // {}) |
     .notifications.events[$e] = {enabled: $s}')
done
echo "$CONFIG" > "$CONFIG_FILE"
```

### Step 7: Test the Configuration

```bash
MENTION_PREFIX=""
if [ -n "$MENTION" ]; then
  MENTION_PREFIX="${MENTION}\n"
fi

curl -s -o /dev/null -w "%{http_code}" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"${MENTION_PREFIX}tinycode test notification - Slack is configured!\"}" \
  "$WEBHOOK_URL"
```

Common errors:
- **403 Forbidden**: Webhook URL is invalid or revoked
- **404 Not Found**: Webhook URL is incorrect

### Step 8: Confirm

Only print the "Configured!" confirmation if:
- The test notification returned HTTP 200, OR
- The user explicitly chose "No, I'll test later" (skip)

If the test failed, report the specific error and stop — do not print the success confirmation until the issue is resolved.

```
Slack Notifications Configured!

  Mention:  <@U1234567890> (or "none")
  Events:   session-end, input-needed

Config saved to: ~/.config/tinycode/notifications-config.json

You can also set these via environment variables:
  TINYCODE_SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
  TINYCODE_SLACK_MENTION=<@U1234567890>
```

### Slack Mention Formats

| Type | Format | Example |
|------|--------|---------|
| User | `<@MEMBER_ID>` | `<@U1234567890>` |
| Channel | `<!channel>` | `<!channel>` |
| Here | `<!here>` | `<!here>` |
| Everyone | `<!everyone>` | `<!everyone>` |
