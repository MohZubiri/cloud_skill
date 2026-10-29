# مهارة `/delegate` لـ Claude Code

سير عمل **«خطّط بالغالي، ابحث بالرخيص، نفّذ بكودكس»**.

الجلسة الرئيسية في Claude Code (النموذج الغالي) تفكّر وتكتب المواصفة فقط. كل قراءة واسعة للكود،
وكل تنفيذ، وكل تشغيل اختبارات يجري خارج سياقها: على وكلاء رخيصين (Haiku) أو على OpenAI Codex CLI.
النتيجة: مهام بناء كاملة بتكلفة سياق صغيرة، ومع تحقق مستقل لا يعتمد على ما يقوله Codex عن نفسه.

```
/delegate <وصف المهمة>
   │
   ├─ scout (Haiku)      يحدد أين يقع الشيء في الكود: path:line
   ├─ المواصفة            تُكتب في <project>/.claude/specs/<slug>.md  (أو عبر planner/Opus)
   ├─ builder (Haiku)    يشغّل codex-run.sh ← codex exec ← ينفّذ المواصفة
   ├─ verifier (Haiku)   يشغّل أمر التحقق من المواصفة ويعيد المخرجات الحقيقية
   └─ تقرير              الملفات المتغيرة (diff --stat) + نتيجة التحقق — بلا commit ولا push
```

## المحتويات

| الملف | يُثبَّت في | الدور |
|---|---|---|
| `skills/delegate/SKILL.md` | `~/.claude/skills/delegate/` | تعريف المهارة وخطواتها وقواعدها |
| `skills/delegate/templates/spec.md` | `~/.claude/skills/delegate/templates/` | قالب المواصفة التي تُسلَّم إلى Codex |
| `skills/delegate/scripts/codex-run.sh` | `~/.claude/skills/delegate/scripts/` | يشغّل Codex بلا تفاعل على المواصفة ويحفظ السجل |
| `agents/scout.md` | `~/.claude/agents/` | باحث قراءة فقط (Haiku) |
| `agents/planner.md` | `~/.claude/agents/` | يكتب المواصفة (Opus) حين تكون الجلسة على نموذج رخيص |
| `agents/builder.md` | `~/.claude/agents/` | يشغّل `codex-run.sh` ويعيد آخر رسالة من Codex |
| `agents/verifier.md` | `~/.claude/agents/` | يشغّل أمر التحقق ويعيد أول الأسطر الفاشلة |
| `install.sh` | — | ينسخ ما سبق إلى `~/.claude` ويفحص المتطلبات |

> لا يوجد وكيل اسمه `codex`: Codex أداة خارجية (سطر أوامر من OpenAI)، والوكيل الذي يشغّلها هو `builder`.

## المتطلبات

1. **Claude Code** (الطرفية أو إضافة VS Code) مسجَّل الدخول، وحسابك يتيح نموذجَي `haiku` و`opus`.
2. **OpenAI Codex CLI** على `PATH` ومسجَّل الدخول:
   ```bash
   npm install -g @openai/codex
   codex login            # يفتح المتصفح
   codex login status     # يجب أن يطبع "Logged in"
   ```
3. `git`.
4. لينكس أو macOS. على Windows استعمل WSL (المسار `~/.claude` وbash مفترضان).

## التثبيت

```bash
git clone https://github.com/MohZubiri/cloud_skill.git
bash cloud_skill/install.sh
```

السكربت ينسخ الملفات السبعة إلى `~/.claude/`، يضبط صلاحية التنفيذ لـ `codex-run.sh`، ثم يطبع حالة
`claude` و`codex` و`git`. آمن لإعادة التشغيل: أي ملف موجود بمحتوى مختلف يُحفظ منه `.bak-<تاريخ>` قبل استبداله.
للتثبيت في مكان غير `~/.claude` مرّر `CLAUDE_HOME=/path bash cloud_skill/install.sh`.

### التحقق من التثبيت

```bash
ls ~/.claude/skills/delegate ~/.claude/agents
codex login status
```
ثم افتح Claude Code داخل أي مشروع واكتب `/delegate` — يجب أن تظهر المهارة في الإكمال التلقائي،
وتظهر الوكلاء الأربعة `scout` و`planner` و`builder` و`verifier` في قائمة الوكلاء.

## طريقة الاستخدام

الصيغة: `/delegate <وصف المهمة | مسار مواصفة جاهزة> [مجلد المشروع]`

```text
/delegate أضف عمود previous_cost لجدول subscription_types مع هجرة واختبار
/delegate .claude/specs/subscription-previous-cost.md
/delegate أضف نقطة API لإرجاع آخر 10 طلبات للعميل  /home/me/projects/api
```

ما يحدث خطوة بخطوة:

1. إن كان الوسيط الأول ملفاً موجوداً فهو المواصفة ويُقفز مباشرة إلى التنفيذ. وإلا فهو وصف مهمة.
2. تُكتب المواصفة في `<project>/.claude/specs/<slug>.md` من القالب. حين تحتاج الجلسة معرفة أين يقع
   شيء في الكود تسأل `scout` سؤالاً ضيقاً واحداً بدل فتح الملفات بنفسها. وإن كانت الجلسة على نموذج
   رخيص تستدعي `planner` ليكتب المواصفة.
3. `builder` يشغّل Codex على المواصفة. السجل الكامل لا يدخل سياق الجلسة؛ يصلها آخر رسالة و`diff --stat` فقط.
4. `verifier` يشغّل «أمر التحقق» المكتوب في المواصفة (اختبارات/lint) ويعيد النتيجة الفعلية.
5. نجاح: تُبلَّغ بالملفات المتغيرة ونتيجة التحقق. فشل: يُعاد `builder` **مرة واحدة** بمواصفة تحوي
   الخطأ الفعلي؛ فإن فشل ثانية تتوقف المهارة وتعرض أول الأسطر الفاشلة وتسألك سؤالاً تشخيصياً واحداً.

**القواعد الثابتة**

- لا `commit` ولا `push` أبداً؛ التغييرات تبقى في شجرة العمل لتراجعها أنت.
- المواصفة تحمل دائماً قواعد المشروع (`CLAUDE.md`، مهارات المستودع في `.claude/skills/*`) والاعتماديات المسموحة.
- للمهام الصغيرة (تعديل سطر، إعادة تسمية، سؤال) لا تستعمل المهارة؛ نفّذها مباشرة.

### كتابة مواصفة بنفسك

انسخ `~/.claude/skills/delegate/templates/spec.md` إلى `<project>/.claude/specs/<slug>.md` واملأ كل
الأقسام. قسم **Verification command** إلزامي وسطر shell واحد بالضبط (مثل
`vendor/bin/pest tests/Feature/X.php`)؛ هو ما يشغّله `verifier` حرفياً.

### متغيرات البيئة

| المتغير | الافتراضي | المعنى |
|---|---|---|
| `CODEX_SANDBOX` | `workspace-write` | وضع عزل Codex: `workspace-write` (كتابة في المشروع، بلا شبكة) أو `read-only` أو `danger-full-access` (يلزم لتثبيت حزم؛ المهارة تخبرك قبل استعماله) |
| `CODEX_MODEL` | إعدادات Codex | النموذج الذي يستعمله Codex؛ يمكن تمريره أيضاً وسيطاً ثالثاً لـ `codex-run.sh` |
| `CLAUDE_HOME` | `~/.claude` | وجهة التثبيت في `install.sh` |

### السجلات والأوامر اليدوية

```bash
# تشغيل Codex يدوياً على مواصفة بلا Claude
bash ~/.claude/skills/delegate/scripts/codex-run.sh <spec.md> <project-dir> [model]

# حالة الدخول إلى Codex
codex login status

# مراجعة كود بكودكس على المستودع الحالي (بديل رخيص لمراجعة الجلسة الرئيسية)
codex exec review -C <project-dir> "Review uncommitted changes for bugs"

# سجلات التشغيلات: ملف .log كامل و -last-message.md لآخر رسالة، لكل مشروع
ls -t ~/.cache/codex-runs/<project-name>/
```

## التحديث والإزالة

```bash
# تحديث
cd cloud_skill && git pull && bash install.sh

# إزالة
rm -rf ~/.claude/skills/delegate ~/.claude/agents/{scout,planner,builder,verifier}.md
```

## أسئلة شائعة

- **تظهر المهارة لكن `builder` يفشل فوراً** — غالباً `codex` غير مثبّت أو غير مسجَّل الدخول؛ شغّل `codex login status`.
- **Codex لا يستطيع تثبيت حزمة** — الوضع الافتراضي بلا شبكة؛ أعد التشغيل مع `CODEX_SANDBOX=danger-full-access`.
- **أين أرى ما فعله Codex بالتفصيل؟** — في `~/.cache/codex-runs/<project-name>/` (المسار يأتي في تقرير `builder`).
- **لماذا لا يعمل commit؟** — بالتصميم؛ المهارة تترك المراجعة والالتزام لك.
