# Plaster

<!-- See also: patches.md for general patch best practices -->

<a id="PLSTR-001"></a>

## ✅ Plaster Patch Patterns Should Match Specific Context

**Plaster patch config `re_pattern` should generally match method names or other relevant context to ensure a single, targeted match.** Simple patterns can be used when the intention is to match all instances of a particular pattern in a file.

```yaml
# ❌ WRONG - overly broad pattern that might match multiple locations
re_pattern: 'return false;'

# ✅ CORRECT - matches method name and context for targeted replacement
re_pattern: 'bool IsFeatureEnabled[\(\)\S\s\{\}]+?(return false);\s+^\}'

# ✅ ALSO CORRECT - simple pattern when all instances should match
# (Use this intentionally when you want to replace every occurrence)
re_pattern: 'kOldConstant'
```

Matching specific context (method names, surrounding code) makes patches more maintainable and prevents accidental matches during Chromium updates. Use broad patterns only when you explicitly intend to replace all occurrences.

---
