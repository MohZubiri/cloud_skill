# <عنوان المهمة بسطر واحد>

## Goal
<فقرة واحدة: ما الذي يجب أن يعمل بعد التنفيذ، من منظور المستخدم.>

## Context
<مسارات بأرقام أسطر من scout. مثال: `app/Services/X.php:42-80` يحوي المنطق الحالي. N/A لمشروع جديد.>

## Scope
Do:
- <ما يجب فعله>
Do NOT:
- <ما يُمنع لمسه>

## Steps
1. <خطوة محددة بملف ودالة>
2. ...

## Acceptance criteria
- [ ] <معيار قابل للاختبار بأمر>
- [ ] ...

## Verification command
```bash
<سطر واحد بالضبط، مثل: python3 -m pytest tests/ -q  أو  vendor/bin/pest tests/Feature/X>
```

## Constraints
- No git commit / push. Leave changes in the working tree.
- <قواعد المشروع: ملف القواعد، الأنماط الممنوعة، الاعتماديات المسموحة>
- Report: list of files changed + exact verification output at the end.
