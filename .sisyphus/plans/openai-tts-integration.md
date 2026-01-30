# OpenAI Speech API Integration for TTS Service

## TL;DR

> **Quick Summary**: 集成 OpenAI Speech API 作为新的 TTS 后端选项，复用现有 OpenAI API Key 配置，禁用 rate/pitch UI 控件
>
> **Deliverables**:
> - OpenaiTtsBackend 实现类
> - 更新 TTS 工厂和设置 UI
> - 完整的手动验证流程
>
> **Estimated Effort**: Medium (1-2 days)
> **Parallel Execution**: NO - sequential tasks
> **Critical Path**: OpenaiTtsBackend → OnlineTts Backend Update → UI Updates → Testing

---

## Context

### Original Request
用户要求分析当前 TTS 服务架构，为集成 OpenAI Speech API 做准备，并创建集成工作计划。

### Interview Summary

**Key Discussions**:
- **API Key 配置**: 选择复用现有 OpenAI AI 配置（`Prefs().getAiConfig('openai')`），不创建独立 TTS 配置
- **Rate/Pitch 处理**: OpenAI API 不支持这些参数，选择在 UI 中禁用相关控件
- **测试策略**: 选择手动验证方式，不设置测试框架

**Research Findings**:
- 项目已通过 `langchain_openai` 集成 OpenAI 用于 AI 聊天
- 配置存储模式：`Prefs().saveAiConfig('openai', config)`
- OpenAI Speech API endpoint: `https://api.openai.com/v1/audio/speech`
- 6 个固定声音：alloy, echo, fable, onyx, nova, shimmer
- 不支持 rate/pitch 参数，输出格式仅 MP3

### Oracle Review

**Identified Gaps (addressed)**:
- **API Key 消耗风险**: TTS 使用可能消耗聊天配额，添加错误提示
- **错误处理缺失**: OpenAI API 错误需要正确传播到 UI，添加异常映射
- **网络弹性**: 间歇性网络中断处理，添加超时和重试逻辑
- **并发使用**: 同一 API Key 的多个 TTS 请求，利用现有重试机制

**Suggestions incorporated**:
- 添加语音常量类提高可维护性
- 改进错误处理和用户友好消息
- 添加配置验证逻辑

**Self-Review: Gap Classification**

| Gap Type | Resolution |
|-----------|------------|
| MINOR: Language keys missing | Use generic English messages or check L10n for existing keys |
| MINOR: Icon resource reference | Use existing AI service icon pattern from ai.dart |
| AMBIGUOUS: Service ID case | Use lowercase 'openai' matching existing code patterns |
| AMBIGUOUS: Error message localization | Use clear English messages, add L10n keys in future |

---

## Work Objectives

### Core Objective
在现有 TTS 服务架构中集成 OpenAI Speech API 作为可选后端，保持与现有 SystemTts 和 AzureTts 的一致性。

### Concrete Deliverables
1. `lib/service/tts/openai_tts_backend.dart` - 新建 OpenAI 后端实现
2. `lib/service/tts/online_tts.dart` - 更新 backend getter 支持 'openai'
3. `lib/page/settings_page/narrate.dart` - 添加 OpenAI 服务选项到设置 UI
4. `lib/widgets/reading_page/tts_widget.dart` - 条件隐藏 rate/pitch 控件

### Definition of Done
- [ ] OpenAI 选项出现在 TTS 设置中
- [ ] 语音选择显示 OpenAI 的 6 个声音
- [ ] 选择 OpenAI 时，rate/pitch 滑块隐藏
- [ ] 使用 OpenAI 语音可以正常播放音频
- [ ] 错误正确显示给用户
- [ ] 现有 Azure/System TTS 功能无回归

### Must Have
- 遵循现有 `OnlineTtsBackend` 接口
- 复用现有 OpenAI API Key 配置
- 正确的错误处理和用户提示
- 网络超时和重试机制（利用现有架构）

### Must NOT Have (Guardrails)
- 不要创建独立的 TTS API Key 配置项
- 不要在客户端实现 rate/pitch 音频处理（禁用 UI 即可）
- 不要修改 SystemTts 或 AzureTts 的现有功能
- 不要引入新的依赖（http 包已存在）

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: NO
- **User wants tests**: NO (Manual Verification)
- **Framework**: none

### Manual QA Only

**CRITICAL**: Without automated tests, manual verification MUST be exhaustive.

**By Deliverable Type:**

| Type | Verification Tool | Procedure |
|------|------------------|-----------|
| **Backend API** | curl / httpie | Send test request to OpenAI API |
| **Settings UI** | Flutter App | Navigate to TTS settings, verify OpenAI option |
| **Voice Selection** | Flutter App | Select OpenAI, verify voice list |
| **TTS Playback** | Flutter App | Play test text with OpenAI voice |
| **Error Handling** | Flutter App | Test with invalid API key |

**Evidence Required**:
- Settings UI screenshots showing OpenAI option
- TTS playback screenshot/video
- Error message screenshots
- API request/response logs

---

## Execution Strategy

### Parallel Execution Waves

**NO parallel execution** - Tasks are sequential and build upon each other.

```
Task Flow:
1. OpenaiTtsBackend Implementation → Core backend logic
2. OnlineTts Factory Update → Wire in new backend
3. Settings UI Update → Add OpenAI to service list
4. TTS Widget Update → Hide controls conditionally
5. Testing & Verification → Manual validation
```

### Dependency Matrix

| Task | Depends On | Blocks | Can Parallelize With |
|------|------------|--------|---------------------|
| 1 | None | 2 | None |
| 2 | 1 | 3 | None |
| 3 | 2 | 4 | None |
| 4 | 3 | 5 | None |
| 5 | 4 | None | None |

### Agent Dispatch Summary

| Task | Recommended Agents |
|------|-------------------|
| 1 (Backend) | delegate_task(category="unspecified-low", load_skills=["playwright", "git-master"]) |
| 2 (Factory) | delegate_task(category="quick", load_skills=["git-master"]) |
| 3 (Settings UI) | delegate_task(category="unspecified-low", load_skills=["frontend-ui-ux"]) |
| 4 (TTS Widget) | delegate_task(category="unspecified-low", load_skills=["frontend-ui-ux"]) |
| 5 (Testing) | Manual verification by user |

---

## TODOs

- [ ] 1. 创建 OpenaiTtsBackend 实现

  **What to do**:
  - 创建新文件 `lib/service/tts/openai_tts_backend.dart`
  - 实现 `OnlineTtsBackend` 抽象接口的所有方法
  - 实现 `speak()` 方法调用 OpenAI API
  - 实现 `getVoices()` 返回固定的 6 个声音列表
  - 添加完整的错误处理和用户友好的错误消息
  - 实现 `convertVoiceModel()` 方法（虽然 OpenAI 不需要复杂转换）
  - 添加网络超时处理（10 秒超时，2 次重试）

  **Must NOT do**:
  - 不要创建新的配置项或存储机制
  - 不要尝试实现 rate/pitch 参数传递（OpenAI 不支持）
  - 不要修改现有 AzureTtsBackend 的代码

  **Recommended Agent Profile**:
  > **Category**: `unspecified-low`
    - Reason: Backend implementation with clear requirements, moderate complexity
  > **Skills**: `[]`
    - No specific skills needed for this backend logic
  > **Skills Evaluated but Omitted**:
    - `playwright`: Not needed for backend implementation
    - `git-master`: Will be used separately for commit after all changes

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (first task)
  - **Blocks**: Tasks 2, 3, 4
  - **Blocked By**: None (can start immediately)

  **References** (CRITICAL - Be Exhaustive):

  > The executor has NO context from your interview. References are their ONLY guide.
  > Each reference must answer: "What should I look at and WHY?"

  **Pattern References** (existing code to follow):
  - `lib/service/tts/azure_tts_backend.dart:1-145` - Complete backend implementation pattern, SSML creation, error handling
  - `lib/service/tts/online_tts_backend.dart:1-18` - Abstract interface definition showing required methods
  - `lib/service/tts/online_tts.dart:263-276` - speak() method usage showing how backend is called (voice, rate, pitch parameters)
  - `lib/service/tts/online_tts.dart:36-70` - Backend instantiation and serviceId checking pattern

  **API/Type References** (contracts to implement against):
  - `lib/service/tts/models/tts_voice.dart:1-45` - TtsVoice model structure for voice data
  - `lib/config/shared_preference_provider.dart:799-811` - getAiConfig() method for accessing OpenAI API key
  - `lib/service/tts/online_tts_backend.dart:12-13` - speak() and getVoices() method signatures

  **Test References** (testing patterns to follow):
  - `lib/service/tts/azure_tts_backend.dart:38-67` - Error throwing pattern for API failures
  - `lib/service/tts/online_tts.dart:254-291` - Retry logic pattern (timeout, maxRetries, exception handling)

  **Documentation References** (specs and requirements):
  - `.sisyphus/drafts/tts-openai-integration.md:98-125` - OpenAI API specification and available voices
  - `https://platform.openai.com/docs/guides/text-to-speech` - Official OpenAI Speech API documentation

  **External References** (libraries and frameworks):
  - Official docs: `https://platform.openai.com/docs/api-reference/audio/createSpeech` - API endpoint details
  - OpenAI voices: `alloy, echo, fable, onyx, nova, shimmer` - Fixed voice list
  - http package: `lib/service/tts/azure_tts_backend.dart:10` - How to use http.post() with headers and body

  **WHY Each Reference Matters**:
  - `azure_tts_backend.dart`: Shows complete backend implementation pattern including SSML, error handling, and voice conversion
  - `online_tts_backend.dart`: Defines the exact method signatures you must implement
  - `shared_preference_provider.dart:799-811`: Shows how to retrieve the OpenAI API key that you'll reuse
  - `online_tts.dart:263-276`: Shows how the backend.speak() method is called with parameters
  - Draft file: Contains the researched OpenAI API details and voice list

  **Acceptance Criteria**:

  > CRITICAL: Acceptance = EXECUTION, not just "it should work".
  > The executor MUST run these commands and verify output.

  **Manual Execution Verification**:

  **For Backend Implementation**:
  - [ ] File created: `lib/service/tts/openai_tts_backend.dart` exists
  - [ ] Class extends `OnlineTtsBackend` and implements all required methods
  - [ ] Service ID getter returns 'openai'
  - [ ] Name getter returns 'OpenAI TTS'
  - [ ] Config fields returns empty list (reusing AI config)
  - [ ] speak() method handles invalid API key by throwing descriptive exception
  - [ ] speak() method makes HTTP POST to `https://api.openai.com/v1/audio/speech`
  - [ ] speak() method includes Authorization header with Bearer token
  - [ ] speak() method body includes: model='tts-1', input=<text>, voice=<voice>, response_format='mp3'
  - [ ] speak() method returns `response.bodyBytes` on success (status 200)
  - [ ] speak() method throws exception with status code and body on error
  - [ ] getVoices() method returns list of 6 TtsVoice objects
  - [ ] getVoices() voices include: alloy, echo, fable, onyx, nova, shimmer
  - [ ] Each TtsVoice has: shortName, name, locale='en-US', gender
  - [ ] Code compiles without errors: `flutter analyze lib/service/tts/openai_tts_backend.dart`

  **Evidence Required**:
  - [ ] Source code file content reviewed
  - [ ] Compilation successful (no errors or warnings)
  - [ ] Method signatures match `OnlineTtsBackend` interface

  **Commit**: YES
  - Message: `feat(tts): add OpenAI Speech API backend implementation`
  - Files: `lib/service/tts/openai_tts_backend.dart`
  - Pre-commit: `flutter analyze`

---

- [ ] 2. 更新 OnlineTts backend getter

  **What to do**:
  - 修改 `lib/service/tts/online_tts.dart` 中的 `backend` getter
  - 添加条件检查 `serviceId == 'openai'`
  - 当条件匹配时，返回 `OpenaiTtsBackend()` 实例
  - 确保导入语句包含新创建的 `openai_tts_backend.dart`
  - 保持现有的 Azure 和其他服务分支不变

  **Must NOT do**:
  - 不要修改 OnlineTts 的任何其他逻辑
  - 不要更改 prefetcher 或 player 循环
  - 不要影响现有 SystemTts 逻辑

  **Recommended Agent Profile**:
  > **Category**: `quick`
    - Reason: Simple conditional logic change, low risk
  > **Skills**: `["git-master"]`
    - `git-master`: For precise code editing and commit after change
  > **Skills Evaluated but Omitted**:
    - `playwright`: No UI changes involved

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (second task)
  - **Blocks**: Task 3
  - **Blocked By**: Task 1 (must have OpenaiTtsBackend implemented first)

  **References** (CRITICAL - Be Exhaustive):

  **Pattern References** (existing code to follow):
  - `lib/service/tts/online_tts.dart:60-70` - Current backend getter with Azure conditional logic
  - `lib/service/tts/online_tts.dart:7-8` - Import statements pattern for backend classes

  **API/Type References** (contracts to implement against):
  - `lib/service/tts/openai_tts_backend.dart` - OpenaiTtsBackend class (created in Task 1)

  **Test References** (testing patterns to follow):
  - None for this simple change

  **Documentation References** (specs and requirements):
  - `.sisyphus/drafts/tts-openai-integration.md:98-125` - Architecture integration point

  **WHY Each Reference Matters**:
  - `online_tts.dart:60-70`: Shows the exact pattern to follow for adding a new backend branch
  - `online_tts.dart:7-8`: Shows where to add the import statement

  **Acceptance Criteria**:

  **For Factory Update**:
  - [ ] Import statement added: `import 'package:anx_reader/service/tts/openai_tts_backend.dart';`
  - [ ] Backend getter includes condition: `if (serviceId == 'openai') return OpenaiTtsBackend();`
  - [ ] Existing Azure branch preserved: `if (serviceId == 'azure') return AzureTtsBackend();`
  - [ ] Code compiles without errors: `flutter analyze lib/service/tts/online_tts.dart`
  - [ ] No syntax errors or import errors

  **Evidence Required**:
  - [ ] Code change reviewed
  - [ ] Compilation successful
  - [ ] Import statement correctly positioned at top of file

  **Commit**: YES
  - Message: `feat(tts): add OpenAI backend to TTS factory`
  - Files: `lib/service/tts/online_tts.dart`
  - Pre-commit: `flutter analyze`

---

- [ ] 3. 添加 OpenAI 选项到 TTS 设置 UI

  **What to do**:
  - 修改 `lib/page/settings_page/narrate.dart`
  - 添加 OpenAI 服务选项到服务选择器
  - 确保服务 ID 为 'openai'
  - 添加服务标题 "OpenAI TTS"
  - 添加适当的 logo/图标资源引用
  - 确保选项正确集成到现有的服务列表中
  - 添加帮助文本或文档链接（如果需要）

  **Must NOT do**:
  - 不要创建新的 API Key 配置字段（复用现有 AI 配置）
  - 不要修改 voice selection 逻辑（OpenAI 的 6 个声音会自动显示）
  - 不要更改现有的 Azure 或 System 选项

  **Recommended Agent Profile**:
  > **Category**: `unspecified-low`
    - Reason: UI modification with clear pattern to follow
  > **Skills**: `["frontend-ui-ux"]`
    - `frontend-ui-ux`: For consistent UI design and user experience
  > **Skills Evaluated but Omitted**:
    - `playwright`: Will be used separately for UI testing

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (third task)
  - **Blocks**: Task 4
  - **Blocked By**: Task 2 (backend must be wired first)

  **References** (CRITICAL - Be Exhaustive):

  **Pattern References** (existing code to follow):
  - `lib/page/settings_page/narrate.dart:92-95` - `_getBackend()` method showing service ID mapping
  - `lib/page/settings_page/narrate.dart:134-141` - Current service display pattern (system vs Microsoft Azure)
  - `lib/page/settings_page/narrate.dart:186-199` - Voice grouping and selection UI pattern

  **API/Type References** (contracts to implement against):
  - `lib/service/tts/openai_tts_backend.dart` - OpenaiTtsBackend.serviceId = 'openai'
  - `lib/service/tts/tts_factory.dart:23-26` - createTts() method showing how serviceId determines backend

  **Test References** (testing patterns to follow):
  - None - UI will be tested manually

  **Documentation References** (specs and requirements):
  - `.sisyphus/drafts/tts-openai-integration.md:98-125` - User decision to reuse existing AI config

  **WHY Each Reference Matters**:
  - `narrate.dart:92-95`: Shows the pattern for mapping service IDs to backend instances
  - `narrate.dart:134-141`: Shows how services are displayed in the UI (simple text)
  - `narrate.dart:186-199`: Shows the voice list UI pattern you may need to reference

  **Acceptance Criteria**:

  **For Settings UI Update**:
  - [ ] OpenAI option added to service selection UI
  - [ ] Option displays as "OpenAI TTS" (or appropriate localized text)
  - [ ] Option can be selected by user
  - [ ] Selecting OpenAI does not crash the app
  - [ ] Code compiles without errors: `flutter analyze lib/page/settings_page/narrate.dart`

  **Manual UI Verification**:
  - [ ] Navigate to TTS settings in app
  - [ ] Tap service selector
  - [ ] Verify "OpenAI TTS" appears in list
  - [ ] Select "OpenAI TTS"
  - [ ] Verify settings page updates without error
  - [ ] Verify voice list shows only OpenAI voices (6 voices)

  **Evidence Required**:
  - [ ] Screenshot of TTS settings showing OpenAI option
  - [ ] Screenshot of voice list showing OpenAI voices
  - [ ] Source code reviewed for service addition

  **Commit**: YES
  - Message: `feat(tts): add OpenAI option to TTS settings`
  - Files: `lib/page/settings_page/narrate.dart`
  - Pre-commit: `flutter analyze`

---

- [ ] 4. 条件隐藏 rate/pitch 控件

  **What to do**:
  - 修改 `lib/widgets/reading_page/tts_widget.dart`
  - 在 `volume()`, `pitch()`, `rate()` 方法的父组件中添加条件
  - 当 `Prefs().ttsService == 'openai'` 时，隐藏 pitch() 和 rate() 滑块
  - 保留 volume() 控件（OpenAI 音频仍然支持音量）
  - 确保隐藏时 UI 布局不崩溃
  - 可选：添加提示信息说明 OpenAI 不支持 rate/pitch 调整

  **Must NOT do**:
  - 不要隐藏 volume 控件（OpenAI 支持音量）
  - 不要修改播放/暂停/停止按钮逻辑
  - 不要影响 SystemTts 或 AzureTts 的控件显示

  **Recommended Agent Profile**:
  > **Category**: `unspecified-low`
    - Reason: Conditional UI rendering, straightforward logic
  > **Skills**: `["frontend-ui-ux"]`
    - `frontend-ui-ux`: For consistent UI/UX when hiding controls
  > **Skills Evaluated but Omitted**:
    - `playwright`: Will be used separately for UI testing

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (fourth task)
  - **Blocks**: Task 5
  - **Blocked By**: Task 3 (UI must show OpenAI option first)

  **References** (CRITICAL - Be Exhaustive):

  **Pattern References** (existing code to follow):
  - `lib/widgets/reading_page/tts_widget.dart:57-76` - volume() widget implementation
  - `lib/widgets/reading_page/tts_widget.dart:78-98` - pitch() widget implementation
  - `lib/widgets/reading_page/tts_widget.dart:100-120` - rate() widget implementation
  - `lib/widgets/reading_page/tts_widget.dart:122-178` - sliders() method that calls volume/pitch/rate
  - `lib/widgets/reading_page/tts_widget.dart:156-172` - Service type display showing current TTS service

  **API/Type References** (contracts to implement against):
  - `lib/config/shared_preference_provider.dart:485-498` - Prefs().ttsService getter

  **Test References** (testing patterns to follow):
  - None - UI will be tested manually

  **Documentation References** (specs and requirements):
  - `.sisyphus/drafts/tts-openai-integration.md:98-125` - User decision to disable UI controls for rate/pitch

  **WHY Each Reference Matters**:
  - `tts_widget.dart:57-76`: Shows the volume slider implementation
  - `tts_widget.dart:78-98`: Shows the pitch slider implementation (to be hidden for OpenAI)
  - `tts_widget.dart:100-120`: Shows the rate slider implementation (to be hidden for OpenAI)
  - `tts_widget.dart:122-178`: Shows where to add conditional logic in sliders() method
  - `tts_widget.dart:156-172`: Shows how current service is displayed (can use this to determine if OpenAI is selected)

  **Acceptance Criteria**:

  **For TTS Widget Update**:
  - [ ] Pitch slider hidden when `Prefs().ttsService == 'openai'`
  - [ ] Rate slider hidden when `Prefs().ttsService == 'openai'`
  - [ ] Volume slider remains visible for all services
  - [ ] UI layout does not break when sliders are hidden
  - [ ] Code compiles without errors: `flutter analyze lib/widgets/reading_page/tts_widget.dart`

  **Manual UI Verification**:
  - [ ] Open book in reading mode
  - [ ] Open TTS controls
  - [ ] With System/Azure selected: Verify pitch and rate sliders are visible
  - [ ] Switch TTS service to OpenAI in settings
  - [ ] Return to reading page, open TTS controls
  - [ ] Verify pitch slider is hidden
  - [ ] Verify rate slider is hidden
  - [ ] Verify volume slider is still visible
  - [ ] Verify TTS plays without errors

  **Evidence Required**:
  - [ ] Screenshot of TTS widget with Azure (pitch/rate visible)
  - [ ] Screenshot of TTS widget with OpenAI (pitch/rate hidden)
  - [ ] Source code reviewed for conditional logic

  **Commit**: YES
  - Message: `feat(tts): hide pitch/rate controls for OpenAI TTS service`
  - Files: `lib/widgets/reading_page/tts_widget.dart`
  - Pre-commit: `flutter analyze`

---

- [ ] 5. 手动验证集成

  **What to do**:
  - 验证 OpenAI API Key 配置：确认在 AI 设置中已配置有效的 OpenAI API Key
  - 测试服务切换：从 System 切换到 OpenAI，再切换到 Azure，验证无崩溃
  - 测试语音选择：在 OpenAI 服务下，选择每个可用的语音（alloy, echo, fable, onyx, nova, shimmer）
  - 测试语音播放：使用每个 OpenAI 语音播放测试文本
  - 测试音量控制：调整音量滑块，验证音量变化
  - 测试错误处理：
    - 移除 API Key，尝试播放（应显示友好的错误消息）
    - 使用无效的 API Key，尝试播放（应显示友好的错误消息）
  - 测试网络恢复：在网络断开后恢复，验证 TTS 继续工作
  - 测试长文本：播放超过 4096 字符的文本，验证分段处理
  - 测试现有功能：确保 Azure 和 System TTS 仍然正常工作

  **Must NOT do**:
  - 不要尝试实现自动化测试（用户选择手动验证）
  - 不要修改任何代码（这是纯验证阶段）

  **Recommended Agent Profile**:
  > **Category**: `unspecified-low`
    - Reason: Manual verification task, no code changes needed
  > **Skills**: `[]`
    - No skills needed for manual testing
  > **Skills Evaluated but Omitted**:
    - All: Not applicable for manual verification

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (final task)
  - **Blocks**: None (final task)
  - **Blocked By**: Tasks 1, 2, 3, 4 (all code changes must be complete)

  **References** (CRITICAL - Be Exhaustive):

  **Pattern References** (existing code to follow):
  - `lib/page/settings_page/narrate.dart:46-90` - Test speak pattern showing how to test voices
  - `lib/widgets/reading_page/tts_widget.dart:31-44` - TTS widget initialization showing play flow
  - `lib/service/tts/online_tts.dart:373-385` - speak() method showing TTS start flow

  **API/Type References** (contracts to implement against):
  - `lib/config/shared_preference_provider.dart:799-811` - Prefs().getAiConfig() for checking API key
  - `lib/service/tts/online_tts.dart:117-119` - getVoices() method for listing available voices

  **Test References** (testing patterns to follow):
  - No automated tests - manual verification only

  **Documentation References** (specs and requirements):
  - `.sisyphus/drafts/tts-openai-integration.md:98-125` - Complete integration requirements and edge cases

  **WHY Each Reference Matters**:
  - `narrate.dart:46-90`: Shows the test speak pattern you should follow to test voices
  - `tts_widget.dart:31-44`: Shows the TTS initialization and play flow to verify
  - `online_tts.dart:373-385`: Shows how TTS starts and what to expect

  **Acceptance Criteria**:

  **Manual Verification Steps**:

  **1. API Key Configuration**:
  - [ ] Navigate to AI settings in app
  - [ ] Verify OpenAI API Key is configured and valid
  - [ ] If not configured, configure with valid key
  - [ ] Test AI chat to verify key works (optional but recommended)

  **2. Service Switching**:
  - [ ] Navigate to TTS settings
  - [ ] Select "System TTS"
  - [ ] Return to reading page
  - [ ] Open TTS widget
  - [ ] Verify System TTS works (play/pause)
  - [ ] Return to TTS settings
  - [ ] Select "Microsoft Azure" (if available)
  - [ ] Return to reading page
  - [ ] Open TTS widget
  - [ ] Verify Azure TTS works
  - [ ] Return to TTS settings
  - [ ] Select "OpenAI TTS"
  - [ ] Verify no crash or error
  - [ ] Return to reading page
  - [ ] Open TTS widget

  **3. Voice Selection**:
  - [ ] Verify voice list shows only 6 voices: alloy, echo, fable, onyx, nova, shimmer
  - [ ] Select "alloy" voice
  - [ ] Play test text
  - [ ] Verify audio plays
  - [ ] Select "echo" voice
  - [ ] Play test text
  - [ ] Verify audio plays
  - [ ] Select "fable" voice
  - [ ] Play test text
  - [ ] Verify audio plays
  - [ ] Select "onyx" voice
  - [ ] Play test text
  - [ ] Verify audio plays
  - [ ] Select "nova" voice
  - [ ] Play test text
  - [ ] Verify audio plays
  - [ ] Select "shimmer" voice
  - [ ] Play test text
  - [ ] Verify audio plays

  **4. UI Controls**:
  - [ ] Verify pitch slider is NOT visible with OpenAI selected
  - [ ] Verify rate slider is NOT visible with OpenAI selected
  - [ ] Verify volume slider IS visible
  - [ ] Adjust volume slider
  - [ ] Play test text
  - [ ] Verify volume change is applied

  **5. Error Handling**:
  - [ ] Go to AI settings
  - [ ] Remove or invalidate OpenAI API Key
  - [ ] Return to TTS widget with OpenAI selected
  - [ ] Attempt to play test text
  - [ ] Verify error message is displayed (not crash)
  - [ ] Restore valid API Key
  - [ ] Verify TTS works again

  **6. Long Text**:
  - [ ] Find or create text longer than 4096 characters
  - [ ] Play the long text
  - [ ] Verify playback continues without error
  - [ ] Verify text is segmented properly (prefetcher should handle this)

  **7. Network Resilience**:
  - [ ] Start playing with OpenAI
  - [ ] Disable network connection
  - [ ] Wait for prefetch to attempt
  - [ ] Re-enable network
  - [ ] Verify playback resumes or can be restarted

  **8. Regression Testing**:
  - [ ] Switch to System TTS
  - [ ] Verify pitch/rate controls are VISIBLE
  - [ ] Play test with System TTS
  - [ ] Verify no errors
  - [ ] Switch to Azure TTS (if configured)
  - [ ] Verify pitch/rate controls are VISIBLE
  - [ ] Play test with Azure TTS
  - [ ] Verify no errors

  **Evidence Required**:
  - [ ] Screenshots of TTS settings with OpenAI selected
  - [ ] Screenshots of voice list showing 6 OpenAI voices
  - [ ] Screenshot of TTS widget with pitch/rate hidden
  - [ ] Screenshot of error message with invalid API key
  - [ ] Verification notes or checklist completed

  **Commit**: NO (this is verification only)

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1 | `feat(tts): add OpenAI Speech API backend implementation` | `lib/service/tts/openai_tts_backend.dart` | `flutter analyze` |
| 2 | `feat(tts): add OpenAI backend to TTS factory` | `lib/service/tts/online_tts.dart` | `flutter analyze` |
| 3 | `feat(tts): add OpenAI option to TTS settings` | `lib/page/settings_page/narrate.dart` | `flutter analyze` |
| 4 | `feat(tts): hide pitch/rate controls for OpenAI TTS service` | `lib/widgets/reading_page/tts_widget.dart` | `flutter analyze` |

---

## Success Criteria

### Verification Commands
```bash
# Analyze code for errors
flutter analyze

# Run app (manual verification steps in Task 5)
flutter run
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] OpenAI backend implemented correctly
- [ ] Factory updated with OpenAI branch
- [ ] Settings UI shows OpenAI option
- [ ] TTS widget hides pitch/rate for OpenAI
- [ ] Manual verification completed (Task 5 checklist)
- [ ] All code compiles without errors
- [ ] No regression with existing TTS services

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|-------|---------|------------|
| API Key quota depletion (TTS using chat quota) | High | Clear documentation, consider separate quota tracking in future |
| OpenAI API rate limits | Medium | Existing retry logic in OnlineTts should handle gracefully |
| User confusion about missing pitch/rate | Low | Clear UI feedback, help text explaining OpenAI limitations |
| Network issues during prefetch | Medium | Existing timeout and retry logic should handle |
| Voice list simplicity (only 6 voices) | Low | Clear communication about available voices |

---

## Future Enhancements (Out of Scope)

The following are NOT included in this plan but could be considered later:

1. **Separate TTS API Key**: Allow distinct API keys for chat vs TTS
2. **Client-side pitch/rate processing**: Implement audio rate adjustment using audioplayers
3. **Voice caching**: Cache generated audio to reduce API calls
4. **Fallback strategy**: Automatic fallback to Azure when OpenAI unavailable
5. **Usage analytics**: Track TTS usage patterns for optimization
6. **HD model support**: Add option for tts-1-hd model when available
