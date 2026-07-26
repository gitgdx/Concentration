#!/usr/bin/env python3
"""
Comparateur EN LECTURE SEULE entre la protection RÉELLE de la branche principale (API GitHub)
et la cible GÉNÉRÉE par `factory_sync.py --emit-branch-protection` (US-00.4, ADR-006).

Trois issues honnêtes, jamais de faux vert :

  exit 0  protection strictement conforme à la cible générée — SEUL chemin où le mot
          « conforme » est autorisé.
  exit 1  dérive : protection absente ou divergente (une ligne `champ | attendu | réel` par
          écart ; contextes de status checks listés séparément en *manquants* et *en trop*).
  exit 2  VÉRIFICATION IMPOSSIBLE — ce n'est PAS un succès : 403 de plan, 403 de droits, 401,
          404 non désambiguïsé, erreur réseau, `gh` absent ET aucun jeton, erreur d'usage,
          ou clé de la cible dont le mapping PUT → GET n'est pas défini.

LECTURE SEULE, ABSOLUE : ce module n'émet que des requêtes GET. Aucune méthode d'écriture (PUT,
POST, PATCH, DELETE), aucun drapeau de méthode passé à `gh api`, aucun chemin d'écriture distante
— il ne doit jamais pouvoir modifier la protection. Ce fichier est d'ailleurs écrit pour que le
contrôle négatif du Story File (critère #11) ne trouve AUCUNE occurrence de drapeau de méthode
d'écriture, pas même en commentaire. La seule écriture disque est l'archive `--raw-out`.
Le seul écrivain reste
`scripts/apply_branch_protection.sh`, PRÊT mais CONDITIONNÉ AU DÉBLOCAGE (403 de plan au
2026-07-26 sur gitgdx/Concentration — cf. docs/adr/ADR-006-protection-branche-principale.md).

La cible est toujours GÉNÉRÉE, jamais dupliquée ici : aucun JSON de protection n'est écrit en dur
dans ce fichier (source unique = factory.config.json via factory_sync.py).

Usage :
  python scripts/check_branch_protection.py [--repo OWNER/NAME] [--raw-out FICHIER]
  python scripts/check_branch_protection.py --from-protection FICHIER --from-branch FICHIER \
                                            [--from-protection-status CODE]

Le mode fixture (`--from-*`) n'émet AUCUN appel réseau (il fonctionne sans `gh` et sans jeton) :
il sert à exercer les chemins exit 0 et exit 1, non observables sur ce dépôt. Toutes ses lignes
sont préfixées `[SIMULATION] ` — une sortie simulée ne doit jamais pouvoir être relue comme une
preuve de l'état réel du dépôt (risque R1 du Story File US-00.4).

Appelé par `python scripts/factory_sync.py --check-remote` via main_from_sync() (import paresseux).
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

import factory_config

ROOT = factory_config.ROOT
SYNC_SCRIPT = "scripts/factory_sync.py"
API_ROOT = "https://api.github.com"
ACCEPT = "application/vnd.github+json"
API_VERSION = "2022-11-28"

EXIT_CONFORME = 0
EXIT_DERIVE = 1
EXIT_IMPOSSIBLE = 2

MSG_IMPOSSIBLE = "VERIFICATION IMPOSSIBLE — ce n'est PAS un succès"
MSG_SIMULE_OK = "conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt"
SIM_PREFIX = "[SIMULATION] "

# Message exact renvoyé par la plateforme quand la protection de branche n'est pas incluse
# dans le plan du dépôt (dépôt privé, compte sans GitHub Pro). Détecté pour attribuer la cause
# « indisponible sur ce plan » — jamais « droits refusés » (cf. AC-1 limite d'US-00.4).
PLAN_MARKER = "upgrade to github pro"

# Booléens du payload PUT à déballer depuis `.enabled` côté réponse GET (l'API n'est pas
# symétrique : une comparaison naïve produirait de fausses dérives).
BOOL_KEYS = (
    "enforce_admins",
    "allow_force_pushes",
    "allow_deletions",
    "required_linear_history",
    "required_conversation_resolution",
)
# Clés de la cible dont le mapping PUT → GET est défini par le §Patterns imposés d'US-00.4.
MAPPED_TOP_KEYS = {
    "required_status_checks",
    "required_pull_request_reviews",
    "restrictions",
    *BOOL_KEYS,
}
MAPPED_RSC_KEYS = {"strict", "contexts"}
MAPPED_PRR_KEYS = {"required_approving_review_count"}

# Rédaction défensive : aucun jeton ne doit atterrir dans reports/ (gitleaks bloquant en
# pre-commit ET en CI). Le motif ci-dessous est une EXPRESSION, jamais un secret.
TOKEN_PATTERN = re.compile(r"\b(gh[pousr]_[A-Za-z0-9]{16,}|github_pat_[A-Za-z0-9_]{16,})")
TOKEN_REDACTED = "<JETON RÉDIGÉ>"


class MappingGap(Exception):
    """La cible générée porte une clé dont le mapping PUT → GET n'est pas défini.

    Lever cette exception plutôt que d'ignorer la clé : une clé non comparée serait un trou
    silencieux dans la vérification — exactement le défaut que cette US corrige.
    """


class UsageError(Exception):
    """Invocation incohérente : la vérification n'a pas lieu (exit 2, jamais exit 1)."""


@dataclass
class ApiResult:
    """Résultat d'une lecture GET (réelle ou simulée depuis une fixture)."""

    command: str
    status: int | None = None
    raw: str = ""
    body: object | None = None
    transport_error: str | None = None
    simulated: bool = False

    @property
    def message(self) -> str:
        if isinstance(self.body, dict):
            return str(self.body.get("message", ""))
        return ""


@dataclass
class Options:
    """Options d'exécution — `main_from_sync()` n'en utilise aucune (résolution automatique)."""

    repo: str | None = None
    raw_out: str | None = None
    from_protection: str | None = None
    from_branch: str | None = None
    from_protection_status: int | None = None
    reads: list[ApiResult] = field(default_factory=list)


class Reporter:
    """Sortie ligne à ligne. En mode fixture, CHAQUE ligne porte le préfixe `[SIMULATION] `.

    Aucune ligne vide n'est émise : une ligne vide échapperait au préfixe et une archive
    simulée pourrait alors être relue comme une preuve d'état réel (R1).
    """

    def __init__(self, simulated: bool) -> None:
        self.prefix = SIM_PREFIX if simulated else ""

    def line(self, text: str) -> None:
        print(f"{self.prefix}{text}")


# ──────────────────────────────────────────────────────────────────────────────────────────
#  Utilitaires
# ──────────────────────────────────────────────────────────────────────────────────────────
def _configure_stdout() -> None:
    """Libellés de status checks avec emoji + console Windows (cp1252) : UTF-8 obligatoire."""
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except AttributeError:  # pragma: no cover — flux non reconfigurable
        pass


def _utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _one_line(text: str) -> str:
    return " ".join((text or "").split())


def _redact(text: str) -> str:
    return TOKEN_PATTERN.sub(TOKEN_REDACTED, text or "")


def _j(value: object) -> str:
    """Rendu JSON compact d'une valeur ; les sentinelles `<...>` sont laissées telles quelles."""
    if isinstance(value, str) and value.startswith("<") and value.endswith(">"):
        return value
    try:
        return json.dumps(value, ensure_ascii=False)
    except (TypeError, ValueError):  # pragma: no cover — valeur non sérialisable
        return repr(value)


def _fmt(field_name: str, expected: object, actual: object) -> str:
    return f"{field_name} | {_j(expected)} | {_j(actual)}"


def _run_sync(flag: str) -> str:
    """Appelle factory_sync.py (source unique) et retourne sa sortie décodée en UTF-8."""
    env = {**os.environ, "PYTHONIOENCODING": "utf-8"}
    out = subprocess.check_output(
        [sys.executable, SYNC_SCRIPT, flag], cwd=str(ROOT), stderr=subprocess.PIPE, env=env
    )
    return out.decode("utf-8").strip()


def load_expected() -> dict:
    """Cible ATTENDUE — toujours GÉNÉRÉE depuis factory.config.json, jamais dupliquée ici."""
    return json.loads(_run_sync("--emit-branch-protection"))


def load_main_branch() -> str:
    return _run_sync("--print-main-branch")


# ──────────────────────────────────────────────────────────────────────────────────────────
#  Résolution du dépôt
# ──────────────────────────────────────────────────────────────────────────────────────────
_REMOTE_RE = re.compile(r"[:/](?P<owner>[^/:]+)/(?P<name>[^/]+?)(?:\.git)?/?$")


def resolve_repo(cli_repo: str | None) -> str:
    """`--repo`, sinon GH_REPO / GITHUB_REPOSITORY, sinon dérivation depuis `git remote origin`."""
    for candidate in (cli_repo, os.environ.get("GH_REPO"), os.environ.get("GITHUB_REPOSITORY")):
        if candidate and candidate.count("/") == 1 and all(candidate.split("/")):
            return candidate.strip()

    try:
        remote = subprocess.check_output(
            ["git", "remote", "get-url", "origin"], cwd=str(ROOT), stderr=subprocess.PIPE
        ).decode("utf-8", errors="replace").strip()
    except (OSError, subprocess.CalledProcessError) as exc:
        raise UsageError(
            "dépôt non résolu : ni --repo, ni GH_REPO/GITHUB_REPOSITORY, et "
            f"`git remote get-url origin` a échoué ({_one_line(str(exc))})"
        ) from exc

    match = _REMOTE_RE.search(remote)
    if not match:
        raise UsageError(f"dépôt non résolu depuis l'URL du remote origin : {remote!r}")
    return f"{match.group('owner')}/{match.group('name')}"


# ──────────────────────────────────────────────────────────────────────────────────────────
#  Transport — GET uniquement (aucune méthode d'écriture n'est atteignable depuis ce module)
# ──────────────────────────────────────────────────────────────────────────────────────────
def _parse_body(raw: str) -> object | None:
    try:
        return json.loads(raw)
    except (json.JSONDecodeError, TypeError):
        return None


_GH_HTTP_RE = re.compile(r"\(HTTP (?P<code>\d{3})\)")


def _get_via_gh(gh_bin: str, path: str) -> ApiResult:
    """`gh api <path>` — GET par défaut, aucun drapeau de méthode n'est passé.

    ⚠️ Comportement de `gh` sur une erreur HTTP (vérifié le 2026-07-26 sur un 403) : le CORPS
    JSON brut part sur stdout, le message humain (`gh: … (HTTP 403)`) sur stderr, et le CODE DE
    SORTIE est 1. Cet exit 1 de `gh` n'est PAS une dérive : le statut réel est lu dans le champ
    `status` du corps JSON (ou, à défaut, dans `(HTTP nnn)` de stderr).
    """
    result = ApiResult(command=f"gh api {path}")
    try:
        proc = subprocess.run(
            [gh_bin, "api", path], capture_output=True, cwd=str(ROOT), check=False
        )
    except OSError as exc:
        result.transport_error = f"`gh api` inexécutable : {_one_line(str(exc))}"
        return result

    result.raw = proc.stdout.decode("utf-8", errors="replace")
    stderr = proc.stderr.decode("utf-8", errors="replace")
    result.body = _parse_body(result.raw)

    if proc.returncode == 0:
        result.status = 200
        return result

    # Exit non nul : lire le statut dans le corps, JAMAIS l'assimiler à une dérive.
    if isinstance(result.body, dict) and "status" in result.body:
        try:
            result.status = int(str(result.body["status"]))
            return result
        except (TypeError, ValueError):
            pass
    match = _GH_HTTP_RE.search(stderr)
    if match:
        result.status = int(match.group("code"))
        return result

    result.transport_error = (
        f"`gh api {path}` a échoué (code de sortie {proc.returncode}) sans statut HTTP "
        f"exploitable — stderr : {_one_line(stderr) or '<vide>'}"
    )
    return result


def _get_via_urllib(path: str, token: str) -> ApiResult:
    """Repli stdlib (zéro nouvelle dépendance). L'en-tête Authorization n'est JAMAIS archivé."""
    url = f"{API_ROOT}/{path.lstrip('/')}"
    result = ApiResult(
        command=(
            f"GET {url} (urllib.request ; Accept: {ACCEPT} ; "
            "Authorization: Bearer <JETON NON ARCHIVÉ>)"
        )
    )
    request = urllib.request.Request(  # noqa: S310 — URL construite, schéma https imposé
        url,
        headers={
            "Accept": ACCEPT,
            "Authorization": f"Bearer {token}",
            "X-GitHub-Api-Version": API_VERSION,
            "User-Agent": "concentration-check-branch-protection",
        },
        method="GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=20) as response:  # noqa: S310
            result.status = response.status
            result.raw = response.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as exc:
        result.status = exc.code
        result.raw = exc.read().decode("utf-8", errors="replace")
    except (urllib.error.URLError, OSError) as exc:
        result.transport_error = f"erreur réseau : {_one_line(str(exc))}"
        return result
    result.body = _parse_body(result.raw)
    return result


def make_reader():
    """Retourne un lecteur GET, ou lève UsageError si aucun transport n'est disponible."""
    gh_bin = shutil.which("gh")
    if gh_bin:
        return lambda path: _get_via_gh(gh_bin, path)

    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if token:
        return lambda path: _get_via_urllib(path, token)

    raise UsageError(
        "`gh` introuvable dans le PATH ET aucun jeton GH_TOKEN/GITHUB_TOKEN : aucune lecture "
        "de l'API n'est possible (si gh est installé, le PATH de la session est peut-être "
        "périmé — rouvrir le terminal)"
    )


# ──────────────────────────────────────────────────────────────────────────────────────────
#  Comparaison — mapping explicite PUT → GET (§Patterns imposés d'US-00.4)
# ──────────────────────────────────────────────────────────────────────────────────────────
def _extract_contexts(rsc: dict) -> set[str]:
    """`contexts` (déprécié mais renseigné) ; repli sur `checks[].context`."""
    contexts = rsc.get("contexts")
    if isinstance(contexts, list) and contexts:
        return {str(c) for c in contexts}
    checks = rsc.get("checks")
    if isinstance(checks, list):
        return {
            str(c["context"])
            for c in checks
            if isinstance(c, dict) and c.get("context") is not None
        }
    if isinstance(contexts, list):
        return set()
    return set()


def _unwrap_enabled(actual: dict, key: str) -> object:
    """Déballe `{"enabled": bool}` côté GET ; sentinelle lisible si la forme est inattendue."""
    if key not in actual:
        return "<clé absente de la réponse GET>"
    value = actual[key]
    if isinstance(value, bool):
        return value
    if isinstance(value, dict):
        if "enabled" not in value:
            return "<sous-clé .enabled absente>"
        return value["enabled"]
    return f"<type inattendu : {type(value).__name__}>"


def _guard_mapping(expected: dict) -> None:
    """Toute clé de la cible non couverte par le mapping = vérification impossible (jamais
    silencieusement ignorée : ce serait un trou dans la preuve)."""
    unknown = sorted(set(expected) - MAPPED_TOP_KEYS)
    if unknown:
        raise MappingGap(
            "clés de la cible générée non couvertes par le mapping PUT → GET d'US-00.4 : "
            + ", ".join(unknown)
        )
    rsc = expected.get("required_status_checks")
    if isinstance(rsc, dict):
        unknown = sorted(set(rsc) - MAPPED_RSC_KEYS)
        if unknown:
            raise MappingGap(
                "clés de required_status_checks non couvertes par le mapping : " + ", ".join(unknown)
            )
    prr = expected.get("required_pull_request_reviews")
    if isinstance(prr, dict):
        unknown = sorted(set(prr) - MAPPED_PRR_KEYS)
        if unknown:
            raise MappingGap(
                "clés de required_pull_request_reviews non couvertes par le mapping : "
                + ", ".join(unknown)
            )
    if expected.get("restrictions") is not None:
        raise MappingGap(
            "la cible générée porte `restrictions` NON nul : le mapping PUT → GET de ce cas "
            "n'est pas défini par US-00.4 — comparer serait deviner"
        )


def compare(expected: dict, actual: dict) -> tuple[list[str], list[str]]:
    """Compare la cible (format PUT) à une réponse GET. Retourne (lignes OK, lignes d'écart).

    Lève MappingGap si la cible porte une clé non mappée (→ exit 2, jamais exit 0/1).
    """
    _guard_mapping(expected)
    ok: list[str] = []
    diffs: list[str] = []

    # 1. required_status_checks.strict + contexts (ensembliste)
    exp_rsc = expected.get("required_status_checks")
    if isinstance(exp_rsc, dict):
        act_rsc = actual.get("required_status_checks")
        if not isinstance(act_rsc, dict):
            diffs.append(
                _fmt(
                    "required_status_checks",
                    "objet présent (strict + contexts)",
                    "<clé absente de la réponse GET — aucun status check requis>",
                )
            )
        else:
            exp_strict = exp_rsc.get("strict")
            act_strict = act_rsc["strict"] if "strict" in act_rsc else "<clé absente>"
            target = "required_status_checks.strict"
            if act_strict == exp_strict:
                ok.append(_fmt(target, exp_strict, act_strict))
            else:
                diffs.append(_fmt(target, exp_strict, act_strict))

            exp_ctx = {str(c) for c in (exp_rsc.get("contexts") or [])}
            act_ctx = _extract_contexts(act_rsc)
            missing = sorted(exp_ctx - act_ctx)
            extra = sorted(act_ctx - exp_ctx)
            for ctx in missing:
                diffs.append(
                    _fmt("required_status_checks.contexts (MANQUANT)", ctx, "<absent de la réponse GET>")
                )
            for ctx in extra:
                diffs.append(
                    _fmt("required_status_checks.contexts (EN TROP)", "<absent de la cible générée>", ctx)
                )
            for ctx in sorted(exp_ctx & act_ctx):
                ok.append(_fmt("required_status_checks.contexts", ctx, ctx))

    # 2. required_pull_request_reviews.required_approving_review_count
    #    Objet ou clé ABSENT = ÉCART, et non un zéro : `0` approbation ≠ pas de PR exigée.
    exp_prr = expected.get("required_pull_request_reviews")
    if isinstance(exp_prr, dict):
        exp_count = exp_prr.get("required_approving_review_count")
        target = "required_pull_request_reviews.required_approving_review_count"
        act_prr = actual.get("required_pull_request_reviews")
        if not isinstance(act_prr, dict):
            diffs.append(
                _fmt(
                    "required_pull_request_reviews",
                    f"objet présent, required_approving_review_count={_j(exp_count)} "
                    "(pull request EXIGÉE)",
                    "<objet absent de la réponse GET — aucune pull request exigée>",
                )
            )
        elif "required_approving_review_count" not in act_prr:
            diffs.append(
                _fmt(target, exp_count, "<clé absente — aucune pull request exigée>")
            )
        else:
            act_count = act_prr["required_approving_review_count"]
            if act_count == exp_count:
                ok.append(_fmt(target, exp_count, act_count))
            else:
                diffs.append(_fmt(target, exp_count, act_count))

    # 3. Booléens déballés depuis `.enabled`
    for key in BOOL_KEYS:
        if key not in expected:
            continue
        exp_val = expected[key]
        act_val = _unwrap_enabled(actual, key)
        target = f"{key} (GET: {key}.enabled)"
        if act_val == exp_val and isinstance(act_val, bool):
            ok.append(_fmt(target, exp_val, act_val))
        else:
            diffs.append(_fmt(target, exp_val, act_val))

    # 4. restrictions : null côté PUT ⇒ clé ABSENTE côté GET = conforme ; présence = écart.
    if "restrictions" in expected:
        target = "restrictions"
        if "restrictions" not in actual:
            ok.append(_fmt(target, None, "<clé absente de la réponse GET — aucune restriction>"))
        else:
            diffs.append(
                _fmt(target, None, "<clé PRÉSENTE dans la réponse GET — restrictions en place>")
            )

    return ok, diffs


# ──────────────────────────────────────────────────────────────────────────────────────────
#  Archivage des réponses brutes (--raw-out) — sans en-tête Authorization, sans jeton
# ──────────────────────────────────────────────────────────────────────────────────────────
def write_raw(path_str: str, repo: str, branch: str, reads: list[ApiResult]) -> Path:
    out_path = Path(path_str)
    if not out_path.is_absolute():
        out_path = Path.cwd() / out_path
    out_path.parent.mkdir(parents=True, exist_ok=True)

    lines = [
        "# Réponses BRUTES de l'API GitHub — archive produite par "
        "scripts/check_branch_protection.py (lecture seule, GET uniquement).",
        f"# Horodatage UTC de l'archive : {_utc_now()}",
        f"# Dépôt : {repo} · branche principale : {branch}",
        "# Aucun en-tête Authorization, aucun jeton n'est écrit dans ce fichier "
        "(rédaction imposée — gitleaks bloquant).",
    ]
    for read in reads:
        lines += [
            "",
            "=" * 88,
            f"# Commande exacte : {_redact(read.command)}",
            f"# Horodatage UTC   : {_utc_now()}",
            f"# Code HTTP        : {read.status if read.status is not None else '<aucun>'}",
        ]
        if read.transport_error:
            lines.append(f"# Erreur transport : {_redact(read.transport_error)}")
        lines += ["=" * 88, _redact(read.raw) if read.raw else "<corps vide>"]

    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    return out_path


# ──────────────────────────────────────────────────────────────────────────────────────────
#  Issues
# ──────────────────────────────────────────────────────────────────────────────────────────
def _impossible(rep: Reporter, cause: str, http: int | None = None) -> int:
    """Exit 2. Le mot « conforme » est proscrit ici : un exit 2 n'est ni un succès, ni un échec."""
    rep.line(MSG_IMPOSSIBLE)
    if http is not None:
        rep.line(f"  Code HTTP : {http} — {cause}")
    else:
        rep.line(f"  Cause : {cause} (aucun code HTTP obtenu)")
    rep.line(
        "  Portée : l'état réel de la protection n'a PAS été lu — ce constat n'atteste ni la "
        "présence, ni l'absence de dérive. À SIGNALER (dette maintenue ouverte)."
    )
    return EXIT_IMPOSSIBLE


def _derive(rep: Reporter, header: str, diffs: list[str]) -> int:
    """Exit 1. Le mot « conforme » est proscrit ici aussi (interdit hors exit 0)."""
    rep.line(f"DÉRIVE DÉTECTÉE — {header}")
    rep.line(f"  {len(diffs)} écart(s) entre la cible générée et l'état lu :")
    rep.line("  champ | attendu | réel")
    for diff in diffs:
        rep.line(f"  {diff}")
    return EXIT_DERIVE


# ──────────────────────────────────────────────────────────────────────────────────────────
#  Orchestration
# ──────────────────────────────────────────────────────────────────────────────────────────
def _load_fixture(path_str: str, label: str) -> ApiResult:
    path = Path(path_str)
    if not path.is_absolute():
        path = Path.cwd() / path
    if not path.exists():
        raise UsageError(f"fixture {label} introuvable : {path_str}")
    raw = path.read_text(encoding="utf-8")
    body = _parse_body(raw)
    if body is None:
        raise UsageError(f"fixture {label} n'est pas un JSON valide : {path_str}")
    return ApiResult(
        command=f"<fixture {label} : {path_str}> — AUCUN appel réseau",
        status=200,
        raw=raw,
        body=body,
        simulated=True,
    )


def _validate_options(opts: Options) -> bool:
    """Valide l'appairage des drapeaux `--from-*`. Retourne True si mode fixture."""
    has_protection = bool(opts.from_protection)
    has_branch = bool(opts.from_branch)
    if has_protection != has_branch:
        raise UsageError(
            "--from-protection et --from-branch vont obligatoirement PAR PAIRE (l'ambiguïté du "
            "404 se lève en croisant les deux lectures) — l'un sans l'autre est une erreur "
            "d'usage, jamais une dérive"
        )
    simulated = has_protection and has_branch
    if not simulated:
        if opts.from_protection_status is not None:
            raise UsageError(
                "--from-protection-status n'a de sens qu'avec --from-protection ET --from-branch"
            )
        return False
    if opts.raw_out:
        raise UsageError(
            "--raw-out est refusé en mode fixture : archiver une réponse SIMULÉE comme une "
            "réponse brute de l'API la rendrait relisible comme une preuve d'état réel (R1)"
        )
    if opts.repo:
        raise UsageError("--repo est sans objet en mode fixture (aucun appel réseau n'est émis)")
    return True


def _attribute(rep: Reporter, expected: dict, protection: ApiResult, branch_res: ApiResult,
               repo: str, branch: str) -> int:
    """Attribue l'issue selon le code HTTP (tableau d'attribution du §Patterns imposés)."""
    if protection.transport_error:
        return _impossible(rep, protection.transport_error)
    status = protection.status

    if status == 200:
        if not isinstance(protection.body, dict):
            return _impossible(
                rep,
                "réponse 200 dont le corps n'est pas un objet JSON de protection exploitable",
                http=200,
            )
        ok, diffs = compare(expected, protection.body)
        rep.line(
            f"Comparaison champ par champ — {repo}:{branch} · "
            f"{len(ok)} champ(s) alignés, {len(diffs)} écart(s)."
        )
        for line in ok:
            rep.line(f"  [OK] {line}")
        if diffs:
            return _derive(rep, f"protection divergente sur {repo}:{branch}", diffs)
        if rep.prefix:
            rep.line(MSG_SIMULE_OK)
        else:
            rep.line(
                f"Protection de {repo}:{branch} — conforme à la cible générée par "
                "`factory_sync.py --emit-branch-protection` (comparaison champ par champ)."
            )
        return EXIT_CONFORME

    if status == 401:
        return _impossible(
            rep,
            "NON AUTHENTIFIÉ (jeton absent, expiré ou invalide) — ce n'est ni un défaut de "
            f"plan, ni une branche non protégée. Message API : {_one_line(protection.message)!r}",
            http=401,
        )

    if status == 403:
        if PLAN_MARKER in protection.message.lower():
            return _impossible(
                rep,
                "protection de branche INDISPONIBLE SUR CE PLAN (dépôt privé sans GitHub Pro) — "
                "ni un défaut de droits, ni un défaut de configuration : aucune commande ne peut "
                f"lire ni appliquer la protection en l'état. Message API : "
                f"{_one_line(protection.message)!r}",
                http=403,
            )
        return _impossible(
            rep,
            "DROITS / ACCÈS REFUSÉS par la plateforme (403 sans message de plan) — le jeton n'a "
            f"probablement pas les droits admin. Message API : {_one_line(protection.message)!r}",
            http=403,
        )

    if status == 404:
        # Ambiguïté du 404 : levée en croisant avec GET …/branches/{b} (champ `protected`,
        # lisible sans droits admin).
        if branch_res.transport_error or branch_res.status != 200 or not isinstance(branch_res.body, dict):
            detail = branch_res.transport_error or f"statut {branch_res.status}"
            return _impossible(
                rep,
                "404 NON DÉSAMBIGUÏSÉ : la lecture croisée de GET "
                f"/repos/{repo}/branches/{branch} a échoué ({_one_line(detail)}) — impossible de "
                "distinguer « branche non protégée » de « protection illisible »",
                http=404,
            )
        protected = branch_res.body.get("protected")
        if protected is False:
            rep.line(
                f"GET /repos/{repo}/branches/{branch}/protection → 404 et "
                f"GET /repos/{repo}/branches/{branch} → \"protected\": false : la branche n'est "
                "réellement PAS protégée (ce n'est pas un défaut de droits)."
            )
            _, diffs = compare(expected, {})
            return _derive(
                rep, f"protection ABSENTE sur {repo}:{branch} (404 + protected == false)", diffs
            )
        if protected is True:
            return _impossible(
                rep,
                f"404 sur la protection alors que GET /repos/{repo}/branches/{branch} annonce "
                "\"protected\": true → la protection existe mais reste ILLISIBLE : droits "
                "insuffisants (admin requis)",
                http=404,
            )
        return _impossible(
            rep,
            f"404 NON DÉSAMBIGUÏSÉ : GET /repos/{repo}/branches/{branch} ne porte pas de champ "
            f"`protected` exploitable (valeur lue : {_j(protected)})",
            http=404,
        )

    return _impossible(
        rep,
        "code HTTP inattendu (ni 200, ni 401, ni 403, ni 404) — la vérification n'a pas abouti. "
        f"Message API : {_one_line(protection.message)!r}",
        http=status,
    )


def run(opts: Options) -> int:
    _configure_stdout()
    try:
        simulated = _validate_options(opts)
    except UsageError as exc:
        # Le préfixe reflète l'intention : toute invocation portant un drapeau --from-* est
        # une simulation, même incomplète.
        rep = Reporter(bool(opts.from_protection or opts.from_branch or opts.from_protection_status))
        return _impossible(rep, f"ERREUR D'USAGE — {exc}")

    rep = Reporter(simulated)

    try:
        expected = load_expected()
        branch = load_main_branch()
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        stderr = getattr(exc, "stderr", b"") or b""
        detail = _one_line(stderr.decode("utf-8", errors="replace")) if stderr else _one_line(str(exc))
        return _impossible(
            rep, f"cible ATTENDUE non générable par `{SYNC_SCRIPT}` : {detail}"
        )

    if simulated:
        rep.line(
            "Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt "
            "réel. Cette sortie n'atteste RIEN de l'état de GitHub."
        )
        try:
            protection = _load_fixture(opts.from_protection or "", "protection")
            branch_res = _load_fixture(opts.from_branch or "", "branche")
        except UsageError as exc:
            return _impossible(rep, f"ERREUR D'USAGE — {exc}")
        protection.status = opts.from_protection_status or 200
        repo = "<owner/repo SIMULÉ>"
        rep.line(f"  Fixture protection : {opts.from_protection} (statut simulé : {protection.status})")
        rep.line(f"  Fixture branche    : {opts.from_branch} (statut simulé : 200)")
    else:
        try:
            repo = resolve_repo(opts.repo)
            reader = make_reader()
        except UsageError as exc:
            return _impossible(rep, str(exc))

        branch_path = f"repos/{repo}/branches/{branch}"
        branch_res = reader(branch_path)
        protection = reader(f"{branch_path}/protection")
        opts.reads = [branch_res, protection]
        rep.line(
            f"Lecture SEULE de l'API GitHub (GET uniquement) — {repo}:{branch} · "
            f"GET {branch_path} → {branch_res.status if branch_res.status is not None else 'échec'}"
            f" · GET {branch_path}/protection → "
            f"{protection.status if protection.status is not None else 'échec'}"
        )
        if opts.raw_out:
            try:
                written = write_raw(opts.raw_out, repo, branch, opts.reads)
                rep.line(f"  Réponses brutes archivées (sans jeton ni Authorization) : {written}")
            except OSError as exc:
                rep.line(f"  [AVERTISSEMENT] archivage --raw-out impossible : {_one_line(str(exc))}")

    try:
        return _attribute(rep, expected, protection, branch_res, repo, branch)
    except MappingGap as exc:
        return _impossible(rep, f"MAPPING INCOMPLET — {exc}")


def main_from_sync() -> int:
    """Point d'entrée de `factory_sync.py --check-remote` : résolution automatique du dépôt et
    de la branche, aucun archivage, aucun mode fixture. Nom CONTRACTUEL (US-00.4, T2/T4)."""
    return run(Options())


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Compare EN LECTURE SEULE la protection réelle de la branche principale à la cible "
            "générée par factory_sync.py --emit-branch-protection. "
            "exit 0 = strictement aligné · 1 = dérive · 2 = vérification impossible."
        )
    )
    parser.add_argument("--repo", metavar="OWNER/NAME", help="dépôt cible (sinon GH_REPO / GITHUB_REPOSITORY / git remote origin)")
    parser.add_argument("--raw-out", metavar="FICHIER", help="archive les réponses brutes des deux GET (UTC, commande exacte, sans jeton)")
    parser.add_argument("--from-protection", metavar="FICHIER", help="fixture de réponse GET .../protection (à appairer avec --from-branch)")
    parser.add_argument("--from-branch", metavar="FICHIER", help="fixture de réponse GET .../branches/{b} (à appairer avec --from-protection)")
    parser.add_argument("--from-protection-status", metavar="CODE", type=int, help="statut HTTP simulé de la fixture de protection (défaut 200)")
    args = parser.parse_args()

    return run(
        Options(
            repo=args.repo,
            raw_out=args.raw_out,
            from_protection=args.from_protection,
            from_branch=args.from_branch,
            from_protection_status=args.from_protection_status,
        )
    )


if __name__ == "__main__":
    sys.exit(main())
