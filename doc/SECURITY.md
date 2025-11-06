# 🔐 Security Best Practices

**Last Updated:** 2025-11-06

This guide covers security best practices when using AI integrations in `flutter_gen_ai_chat_ui`.

---

## ⚠️ Critical: API Key Security

### The Problem

AI provider API keys (OpenAI, Claude, etc.) are **sensitive credentials** that:
- Give access to your API account
- Can incur costs if misused
- Should NEVER be exposed publicly

### ❌ NEVER Do This

```dart
// 🚨 DANGER: Hardcoded API key
OpenAIChatWidget(
  apiKey: 'sk-proj-1234567890abcdefghijklmnopqrstuvwxyz',  // EXPOSED!
  currentUser: user,
)
```

**Why this is dangerous:**
1. **Source Control**: If you commit this to Git, it's in your history forever
2. **GitHub Scanning**: GitHub automatically scans for API keys and may disable them
3. **Decompilation**: Anyone can extract the key from your compiled app
4. **Cost Risk**: Exposed keys can lead to unexpected API bills

---

## ✅ Secure Solutions

### Option 1: Environment Variables (Best for Development)

**How it works:**
- API key is passed at runtime, not in source code
- Different keys for development, staging, production

**Implementation:**

```dart
// In your code (safe to commit)
OpenAIChatWidget(
  apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
  currentUser: user,
)
```

**Running the app:**

```bash
# During development
flutter run --dart-define=OPENAI_API_KEY=your_key_here

# For builds
flutter build apk --dart-define=OPENAI_API_KEY=your_key_here
```

**IDE Configuration:**

**VS Code** (`.vscode/launch.json`):
```json
{
  "configurations": [
    {
      "name": "Flutter (with API key)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=OPENAI_API_KEY=your_key_here"
      ]
    }
  ]
}
```

**Android Studio**:
1. Run → Edit Configurations
2. Additional Run Args: `--dart-define=OPENAI_API_KEY=your_key_here`

---

### Option 2: Flutter Dotenv (Good for Development)

**Install package:**
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

**Create `.env` file (add to `.gitignore`!):**
```
OPENAI_API_KEY=your_key_here
CLAUDE_API_KEY=your_other_key_here
```

**Load and use:**
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

// In your widget
OpenAIChatWidget(
  apiKey: dotenv.env['OPENAI_API_KEY']!,
  currentUser: user,
)
```

**Important:** Add `.env` to `.gitignore`:
```gitignore
# .gitignore
.env
.env.local
.env.*.local
```

---

### Option 3: Secure Backend Proxy (Best for Production)

**Architecture:**
```
Flutter App → Your Backend API → OpenAI API
           (no API key)      (has API key)
```

**Why this is best for production:**
- ✅ API key never leaves your server
- ✅ You can implement rate limiting
- ✅ You can monitor usage per user
- ✅ You can add authentication
- ✅ You can rotate keys without updating app

**Implementation:**

**Backend** (Node.js example):
```javascript
// server.js
const express = require('express');
const OpenAI = require('openai');

const app = express();
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY, // Stored securely on server
});

app.post('/api/chat', authenticate, async (req, res) => {
  // Verify user is authenticated
  const userId = req.user.id;

  // Check rate limits for this user
  if (await isRateLimited(userId)) {
    return res.status(429).json({ error: 'Rate limit exceeded' });
  }

  // Call OpenAI API
  const completion = await openai.chat.completions.create({
    model: 'gpt-3.5-turbo',
    messages: req.body.messages,
    stream: true,
  });

  // Stream response back to client
  for await (const chunk of completion) {
    res.write(chunk);
  }
  res.end();
});
```

**Flutter App:**
```dart
class SecureAIProvider implements AiProvider {
  final String backendUrl;
  final String authToken;

  SecureAIProvider({
    required this.backendUrl,
    required this.authToken,
  });

  @override
  Future<String> sendMessage(String message, {
    List<Map<String, String>>? conversationHistory,
  }) async {
    final response = await http.post(
      Uri.parse('$backendUrl/api/chat'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
        'history': conversationHistory,
      }),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw AiProviderException('Backend error: ${response.statusCode}');
    }
  }

  // Implement other methods...
}
```

---

## 🔒 Additional Security Measures

### 1. Rate Limiting

Protect against abuse by implementing rate limits:

```dart
class RateLimitedAIProvider implements AiProvider {
  final AiProvider _provider;
  final Map<String, List<DateTime>> _userRequests = {};

  static const int maxRequestsPerMinute = 10;

  Future<String> sendMessage(String message, {
    List<Map<String, String>>? conversationHistory,
  }) async {
    final userId = getCurrentUserId();

    // Check rate limit
    if (_isRateLimited(userId)) {
      throw AiProviderException('Rate limit exceeded. Please wait.');
    }

    // Track request
    _trackRequest(userId);

    // Forward to actual provider
    return await _provider.sendMessage(message, conversationHistory: conversationHistory);
  }

  bool _isRateLimited(String userId) {
    final requests = _userRequests[userId] ?? [];
    final oneMinuteAgo = DateTime.now().subtract(Duration(minutes: 1));

    // Remove old requests
    requests.removeWhere((time) => time.isBefore(oneMinuteAgo));

    return requests.length >= maxRequestsPerMinute;
  }

  void _trackRequest(String userId) {
    _userRequests[userId] ??= [];
    _userRequests[userId]!.add(DateTime.now());
  }
}
```

### 2. User Authentication

Ensure only authenticated users can access AI features:

```dart
class AuthenticatedChatWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthUser>(context);

    if (user == null || !user.isAuthenticated) {
      return LoginScreen();
    }

    return OpenAIChatWidget(
      apiKey: await getSecureApiKey(user.id),
      currentUser: user.toChatUser(),
    );
  }
}
```

### 3. Input Sanitization

Sanitize user input to prevent injection attacks:

```dart
String sanitizeInput(String input) {
  // Remove any potential injection attempts
  return input
      .replaceAll(RegExp(r'<script.*?>.*?</script>', multiLine: true), '')
      .replaceAll(RegExp(r'javascript:'), '')
      .trim();
}
```

### 4. Cost Monitoring

Monitor and alert on unusual API usage:

```dart
class CostMonitoringProvider implements AiProvider {
  final AiProvider _provider;
  double _totalCost = 0.0;
  static const double dailyLimit = 10.0; // $10 per day

  @override
  Future<String> sendMessage(String message, {
    List<Map<String, String>>? conversationHistory,
  }) async {
    // Check if over budget
    if (_totalCost >= dailyLimit) {
      throw AiProviderException('Daily cost limit reached. Please try again tomorrow.');
    }

    // Make request
    final response = await _provider.sendMessage(message, conversationHistory: conversationHistory);

    // Update cost tracking
    // (You'd implement actual token counting here)

    return response;
  }
}
```

---

## 📋 Security Checklist

Before deploying your app:

- [ ] No API keys hardcoded in source code
- [ ] `.env` files added to `.gitignore`
- [ ] Environment variables used for local development
- [ ] Backend proxy implemented for production
- [ ] Rate limiting enabled
- [ ] User authentication required
- [ ] Cost monitoring alerts set up
- [ ] API keys stored in secure credential manager (AWS Secrets Manager, etc.)
- [ ] Different API keys for dev/staging/production
- [ ] API key rotation plan in place

---

## 🚨 What to Do If Your Key Is Exposed

If you accidentally commit or expose your API key:

1. **Immediately Revoke the Key**
   - OpenAI: https://platform.openai.com/api-keys
   - Claude: https://console.anthropic.com/settings/keys

2. **Generate a New Key**
   - Create a new key
   - Update your secure storage
   - Never reuse the exposed key

3. **Clean Git History** (if committed)
   ```bash
   # Use BFG Repo-Cleaner or git-filter-branch
   # This is complex - see GitHub's guide:
   # https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository
   ```

4. **Check for Unauthorized Usage**
   - Review your API usage dashboard
   - Look for unusual activity
   - Consider enabling spending limits

5. **Learn and Improve**
   - Implement better security measures
   - Use pre-commit hooks to scan for secrets
   - Train your team on security best practices

---

## 🛡️ Tools to Help

### Secret Scanning

**Pre-commit Hook** (`.git/hooks/pre-commit`):
```bash
#!/bin/bash

# Scan for potential API keys
if git diff --cached | grep -E "sk-[a-zA-Z0-9]{48}" > /dev/null; then
  echo "❌ Potential API key detected! Commit blocked."
  exit 1
fi
```

**GitHub Actions** (`.github/workflows/secret-scan.yml`):
```yaml
name: Secret Scan
on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: trufflesecurity/trufflehog@main
        with:
          path: ./
```

---

## 📚 Additional Resources

- [OWASP Mobile Security Guide](https://owasp.org/www-project-mobile-security/)
- [OpenAI Safety Best Practices](https://platform.openai.com/docs/guides/safety-best-practices)
- [Flutter Security Documentation](https://docs.flutter.dev/security)
- [12-Factor App: Config](https://12factor.net/config)

---

## 💬 Questions?

If you have security concerns or questions:
- Open an issue: https://github.com/hooshyar/flutter_gen_ai_chat_ui/issues
- Label it: `security`
- We'll respond promptly

**Remember: It's better to ask than to risk a security breach!**
