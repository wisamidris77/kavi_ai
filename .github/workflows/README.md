# GitHub Actions CI/CD Workflows

## 🚀 Overview

This repository uses GitHub Actions for comprehensive CI/CD automation. Our workflows handle everything from code quality checks to multi-platform builds and deployments.

## 📋 Workflows

### 1. CI/CD Pipeline (`ci.yml`)
**Trigger:** Push to main/develop, Pull Requests, Manual dispatch

**Purpose:** Main continuous integration pipeline

**Jobs:**
- ✅ Code Quality & Linting
- 🧪 Multi-platform Testing (Linux, macOS, Windows)
- 🏗️ Build Applications (Android, iOS, Web, Desktop)
- 🔒 Security Scanning
- 📊 Coverage Reporting
- 🚀 Deploy to GitHub Pages (Web)
- 📢 Notifications

**Key Features:**
- Parallel testing across platforms
- Code coverage with Codecov integration
- Automatic PR comments with test results
- Build artifacts for all platforms
- Security vulnerability scanning

### 2. Release Pipeline (`release.yml`)
**Trigger:** Version tags (v*.*.*), Manual dispatch

**Purpose:** Production releases and store deployments

**Jobs:**
- 📦 Build all platform releases
- 📝 Generate changelog
- 🚀 Create GitHub release
- 📱 Deploy to app stores
- 🌐 Deploy web version
- 📢 Post-release notifications

**Key Features:**
- Automated changelog generation
- Multi-platform builds (Android AAB/APK, iOS, Web, Desktop)
- Store deployment support (Google Play, App Store, Microsoft Store)
- Asset packaging and versioning
- Release announcements

### 3. Dependency Management (`dependencies.yml`)
**Trigger:** Weekly schedule (Mondays 9 AM UTC), Manual dispatch

**Purpose:** Keep dependencies updated and secure

**Jobs:**
- 🎯 Flutter SDK update check
- 📦 Pub package updates
- 🔒 Security vulnerability audit
- 📜 License compliance check
- 📊 Dependency graph generation

**Key Features:**
- Automated dependency updates with PR creation
- Security vulnerability detection
- License compliance monitoring
- Visual dependency graphs
- Update notifications

### 4. Code Quality & Analysis (`code-quality.yml`)
**Trigger:** Pull Requests, Push to main/develop, Daily schedule, Manual dispatch

**Purpose:** Maintain code quality standards

**Jobs:**
- 📝 Static code analysis
- 🎨 Code formatting checks
- 📖 Documentation coverage
- 🧮 Complexity analysis
- 📊 Test coverage analysis
- ⚡ Performance analysis

**Key Features:**
- Dart code metrics with thresholds
- Auto-formatting on PRs
- Documentation generation
- Cyclomatic complexity checks
- Coverage threshold enforcement (70%)
- Build size analysis

## 🔧 Configuration

### Required Secrets
Configure these in Settings → Secrets and variables → Actions:

```yaml
# Authentication
GITHUB_TOKEN         # Automatically provided
CODECOV_TOKEN       # Optional: Codecov.io integration

# App Signing
ANDROID_KEYSTORE_BASE64    # Android keystore file (base64)
ANDROID_KEY_PROPERTIES     # Android key.properties content

# Store Deployment
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON  # Google Play deployment
APP_STORE_CONNECT_API_KEY         # Apple App Store deployment
APP_STORE_CONNECT_API_KEY_ID      # Apple API Key ID
APP_STORE_CONNECT_API_ISSUER_ID   # Apple API Issuer ID

# External Services
SLACK_WEBHOOK_URL    # Slack notifications
DISCORD_WEBHOOK      # Discord notifications
NETLIFY_AUTH_TOKEN   # Netlify deployment
NETLIFY_SITE_ID      # Netlify site ID
```

### Environment Variables
Update these in workflow files:

```yaml
FLUTTER_VERSION: '3.24.0'  # Your Flutter SDK version
JAVA_VERSION: '17'         # Java version for Android builds
```

## 📊 Workflow Status Badges

Add these badges to your README:

```markdown
![CI/CD](https://github.com/YOUR_USERNAME/kavi/workflows/CI%2FCD%20Pipeline/badge.svg)
![Release](https://github.com/YOUR_USERNAME/kavi/workflows/Release%20Pipeline/badge.svg)
![Dependencies](https://github.com/YOUR_USERNAME/kavi/workflows/Dependency%20Management/badge.svg)
![Code Quality](https://github.com/YOUR_USERNAME/kavi/workflows/Code%20Quality%20%26%20Analysis/badge.svg)
```

## 🚦 Workflow Triggers

| Workflow | Push | PR | Schedule | Tag | Manual |
|----------|------|-----|----------|-----|--------|
| CI/CD | ✅ | ✅ | ❌ | ❌ | ✅ |
| Release | ❌ | ❌ | ❌ | ✅ | ✅ |
| Dependencies | ❌ | ❌ | ✅ | ❌ | ✅ |
| Code Quality | ✅ | ✅ | ✅ | ❌ | ✅ |

## 🎯 Quality Gates

### Test Coverage
- **Minimum:** 70%
- **Target:** 80%+
- **Enforcement:** Fails build if below minimum

### Code Metrics
- **Cyclomatic Complexity:** Max 10
- **Nesting Level:** Max 5
- **Parameters:** Max 4
- **Lines of Code:** Max 50 per function
- **Maintainability Index:** Min 40

### Security
- **Vulnerability Scanning:** Trivy, OWASP
- **Secret Detection:** TruffleHog
- **License Check:** GPL/AGPL detection

## 📝 Usage Examples

### Manual Trigger
```bash
# Trigger CI/CD manually
gh workflow run ci.yml

# Trigger release with version
gh workflow run release.yml -f version=1.2.3 -f prerelease=false

# Update dependencies
gh workflow run dependencies.yml -f update_type=all
```

### Creating a Release
```bash
# Tag and push to trigger release
git tag v1.0.0
git push origin v1.0.0
```

### Skip CI
Add `[skip ci]` or `[ci skip]` to commit message:
```bash
git commit -m "docs: update README [skip ci]"
```

## 🔍 Troubleshooting

### Common Issues

1. **Build Failures**
   - Check Flutter version compatibility
   - Verify dependencies are up to date
   - Review error logs in Actions tab

2. **Test Failures**
   - Run tests locally first: `flutter test`
   - Check for platform-specific issues
   - Review coverage reports

3. **Deployment Issues**
   - Verify secrets are configured correctly
   - Check API keys haven't expired
   - Review deployment logs

### Debugging Workflows

1. **Enable debug logging:**
   - Add secret: `ACTIONS_RUNNER_DEBUG: true`
   - Add secret: `ACTIONS_STEP_DEBUG: true`

2. **SSH into runners (debugging):**
   ```yaml
   - name: Setup tmate session
     uses: mxschmitt/action-tmate@v3
     if: ${{ github.event_name == 'workflow_dispatch' }}
   ```

3. **Check workflow syntax:**
   ```bash
   # Validate workflow files
   actionlint .github/workflows/*.yml
   ```

## 🏗️ Best Practices

1. **Security**
   - Never commit secrets or credentials
   - Use GitHub Secrets for sensitive data
   - Regularly rotate API keys
   - Review security alerts

2. **Performance**
   - Use workflow caching for dependencies
   - Run jobs in parallel when possible
   - Use matrix builds for multi-platform
   - Cancel outdated workflow runs

3. **Maintenance**
   - Keep Flutter version updated
   - Regular dependency updates
   - Monitor workflow usage/costs
   - Clean up old artifacts

4. **Branching Strategy**
   - `main`: Production-ready code
   - `develop`: Integration branch
   - `feature/*`: Feature development
   - `release/*`: Release preparation
   - `hotfix/*`: Emergency fixes

## 📈 Monitoring

### Workflow Metrics
- View in: Actions → Workflow name → ⋮ → View workflow runs
- Monitor: Success rate, duration, frequency

### Cost Management
- Check usage: Settings → Billing & plans → Usage this month
- Free tier: 2,000 minutes/month (public repos: unlimited)
- Optimize: Use Linux runners when possible (1x multiplier)

### Notifications
Configure notifications in:
- Personal: Settings → Notifications
- Repository: Watch → Custom → Actions

## 🔗 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter GitHub Actions](https://github.com/subosito/flutter-action)
- [Action Marketplace](https://github.com/marketplace?type=actions)
- [Workflow Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)

## 📄 License

These workflows are part of the Kavi project and follow the same license.