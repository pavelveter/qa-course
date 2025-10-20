# ruff-black.ps1
# Full Python Dev setup (Ruff, Black, Pytest, Requests, Mypy, UV, cSpell, CI/CD, GitLens)
# Works for Python 3.14 ARM64 or x64
# Run: irm http://192.168.88.45/ruff-black.ps1 | iex

function Ensure-InPath($name, $subpath) {
    if (-not (Test-Path $subpath)) { return }
    $envPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($envPath -notmatch [Regex]::Escape($subpath)) {
        Write-Host "Adding $name to PATH → $subpath" -ForegroundColor Yellow
        [Environment]::SetEnvironmentVariable('Path', "$envPath;$subpath", 'User')
    } else {
        Write-Host "$name path OK → $subpath" -ForegroundColor Green
    }
}

Write-Host "Configuring full Python Dev environment..." -ForegroundColor Cyan

# --- Locate Python ---
$pyCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pyCmd) {
    Write-Host "Python not found. Please install from python.org and add to PATH." -ForegroundColor Red
    exit 1
}
$pythonPath = $pyCmd.Source
Write-Host "Python: $pythonPath" -ForegroundColor Green

# --- Detect architecture suffix (e.g. Python314-arm64) ---
$pyBase = & $pythonPath -c "import sysconfig; print(sysconfig.get_config_var('SOABI') or '')"
$archSuffix = if ($pyBase -match 'arm64') { 'Python314-arm64' } else { 'Python314' }

# --- Define Scripts directory ---
$scriptDir = "$env:APPDATA\Python\$archSuffix\Scripts"
if (-not (Test-Path $scriptDir)) {
    $scriptDir = & $pythonPath -c "import sysconfig; print(sysconfig.get_paths().get('scripts',''))"
}
Ensure-InPath "Python Scripts" $scriptDir

# --- Git & VSCode CLI ---
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) { Ensure-InPath "Git" (Split-Path $git.Source) }

$vscodeBin = "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\bin"
Ensure-InPath "VSCode" $vscodeBin
$code = "$vscodeBin\code.cmd"

# --- pip & package installs ---
& $pythonPath -m ensurepip --upgrade | Out-Null
& $pythonPath -m pip install --upgrade pip | Out-Null

$packages = @("ruff","black","pytest","requests","mypy","uv")
foreach ($pkg in $packages) {
    Write-Host "Installing $pkg..." -ForegroundColor Yellow
    & $pythonPath -m pip install --upgrade $pkg | Out-Null
}

# --- Executables ---
$blackExe = Join-Path $scriptDir "black.exe"
$mypyExe  = Join-Path $scriptDir "mypy.exe"

# --- Install VSCode extensions ---
$extensions = @(
    # Core Python / QA
    "ms-python.python",
    "ms-python.black-formatter",
    "charliermarsh.ruff",
    "ms-python.vscode-pylance",
    "ms-python.mypy-type-checker",
    "LittleFoxTeam.vscode-python-test-adapter",
    "ms-toolsai.jupyter",
    "ms-toolsai.datawrangler",
    "KevinRose.vsc-python-indent",
    "ms-toolsai.vscode-jupyter-keymap",
    "ms-toolsai.vscode-jupyter-cell-tags",

    # DevOps / CI / Docker / YAML
    "GitHub.vscode-github-actions",
    "ms-azuretools.vscode-docker",
    "redhat.vscode-yaml",
    "foxundermoon.shell-format",

    # Git / Collaboration
    "eamodio.gitlens",
    "GitHub.vscode-pull-requests-github",
    "mhutchie.git-graph",

    # Code style / docs / utils
    "streetsidesoftware.code-spell-checker",
    "streetsidesoftware.code-spell-checker-russian",
    "aaron-bond.better-comments",
    "oderwat.indent-rainbow",
    "usernamehw.errorlens",
    "Gruntfuggly.todo-tree",
    "yzhang.markdown-all-in-one",
    "formulahendry.code-runner",
    "wmaurer.change-case"
)
foreach ($ext in $extensions) {
    $installed = & $code --list-extensions | Select-String -SimpleMatch $ext
    if (-not $installed) {
        Write-Host "Installing extension: $ext" -ForegroundColor Yellow
        & $code --install-extension $ext
    } else {
        Write-Host "Extension already installed: $ext" -ForegroundColor Green
    }
}

# --- VSCode settings.json ---
$settingsPath = "$env:APPDATA\Code\User\settings.json"
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$settings = @"
{
    "editor.formatOnSave": true,
    "editor.formatOnSaveMode": "file",

    "[python]": {
        "editor.defaultFormatter": "ms-python.black-formatter",
        "editor.codeActionsOnSave": {
            "source.fixAll.ruff": "explicit",
            "source.organizeImports.ruff": "explicit"
        }
    },

    "python.defaultInterpreterPath": "$($pythonPath.Replace("\","\\"))",
    "black-formatter.importStrategy": "fromEnvironment",
    "black-formatter.path": ["$($blackExe.Replace("\","\\"))"],

    "python.testing.pytestEnabled": true,
    "python.testing.unittestEnabled": false,
    "python.testing.autoTestDiscoverOnSaveEnabled": true,

    "mypy-type-checker.enabled": true,
    "mypy-type-checker.path": ["$($mypyExe.Replace("\","\\"))"],

    "python.languageServer": "Pylance",
    "python.analysis.typeCheckingMode": "basic",
    "python.analysis.diagnosticMode": "workspace",

    "cSpell.language": "en,ru",
    "cSpell.enableFiletypes": ["python","json","yaml","markdown"],
    "cSpell.ignoreWords": ["pytest","asyncio","uvicorn","FastAPI","Pydantic"],

    "chat.disableAIFeatures": true,
    "chat.commandCenter.enabled": false
}
"@
[System.IO.File]::WriteAllText($settingsPath, $settings, $Utf8)
Write-Host "VSCode settings.json written." -ForegroundColor Green

# --- Global pyproject.toml ---
$pyprojectPath = Join-Path $HOME "pyproject.toml"
$pyproject = @"
[tool.black]
line-length = 88
target-version = ["py314"]
skip-string-normalization = false

[tool.ruff]
line-length = 88
target-version = "py314"
select = ["E","F","I"]
ignore = ["E501"]
fix = true
show-fixes = true

[tool.ruff.lint.isort]
combine-as-imports = true
force-sort-within-sections = true
lines-after-imports = 2

[tool.mypy]
python_version = "3.14"
strict = true
warn_unused_configs = true
disallow_untyped_defs = true
check_untyped_defs = true
"@
[System.IO.File]::WriteAllText($pyprojectPath, $pyproject, $Utf8)
Write-Host "pyproject.toml created at $pyprojectPath" -ForegroundColor Green

Write-Host "Setup complete. Restart VSCode and PowerShell for PATH refresh." -ForegroundColor Cyan