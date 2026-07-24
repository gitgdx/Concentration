# 📇 Index des rapports d'audit / QA / sécurité

## Règle de nommage

Tout rapport est rangé **par US** : `reports/US-XXX/<type>.md`
avec `<type>` ∈ `code_review` | `security` | `qa` | `performance`.
Le chemin du rapport est référencé dans `docs/trace/US-XXX/events.jsonl` (champ `evidence.report`) —
`scripts/validate_trace.py` vérifie son existence.

Ne jamais nommer un rapport par sprint ou par lot — un rapport = une US = un type d'audit.
