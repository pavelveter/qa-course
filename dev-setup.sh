#!/usr/bin/env bash
# Usage:
#   curl -fsSL http://192.168.88.47/dev-setup.sh | bash
# Description:
#   Full macOS Python + VSCode environment setup (ARM/x64, Homebrew, pyenv, venv)
#   Installs: ruff, black, pytest, mypy, uv, requests (via isolated venv if needed)
#   Configures VSCode extensions and settings, creates pyproject.toml

set -e

echo "Setting up full Python + VSCode Dev environment on macOS..."

# --- Smart Python detector ---
detect_python() {
  echo "Detecting Python installation..."

  if command -v python3 &>/dev/null; then
    PY=$(command -v python3)
  elif command -v python &>/dev/null; then
    PY=$(command -v python)
  elif command -v brew &>/dev/null; then
    echo "Python not found, installing via Homebrew..."
    brew install python >/dev/null
    PY=$(brew --prefix)/bin/python3
  elif command -v pyenv &>/dev/null; then
    echo "Using pyenv Python..."
    PY=$(pyenv which python3)
  else
    echo "No Python installation found. Install manually (brew install python)."
    exit 1
  fi

  echo "Using Python: $PY"

  if ! $PY -m pip --version >/dev/null 2>&1; then
    echo "Bootstrapping pip..."
    $PY -m ensurepip --upgrade >/dev/null || true
  fi
}

detect_python
PYTHON=$PY

# --- Detect architecture ---
ARCH=$(uname -m)
echo "Architecture: $ARCH"

# --- Scripts dir (where pip installs binaries) ---
SCRIPTS_DIR=$($PYTHON -c "import sysconfig; print(sysconfig.get_paths().get('scripts',''))")
export PATH="$PATH:$SCRIPTS_DIR"
echo "Scripts dir: $SCRIPTS_DIR"

# --- Git ---
if ! command -v git &>/dev/null; then
  echo "Git not found. Installing via Homebrew..."
  brew install git >/dev/null
fi

# --- VSCode CLI ---
VSCODE_APP="/Applications/Visual Studio Code.app"
CODE_CLI="$VSCODE_APP/Contents/Resources/app/bin/code"

if [ ! -x "$CODE_CLI" ]; then
  echo "VSCode CLI not found. Launch VSCode, open Command Palette (Cmd+Shift+P), run:"
  echo "'Shell Command: Install 'code' command in PATH'"
  exit 1
fi

# --- Package installation (pip or pipx fallback) ---
$PYTHON -m ensurepip --upgrade >/dev/null 2>&1 || true
echo "Checking for externally-managed Python environment..."
if ! $PYTHON -m pip install --upgrade pip >/dev/null 2>&1; then
  echo "Detected externally managed Python (Homebrew/pyenv brew build). Using pipx instead."
  if ! command -v pipx &>/dev/null; then
    echo "Installing pipx via Homebrew..."
    brew install pipx >/dev/null
    pipx ensurepath
    export PATH="$PATH:$HOME/.local/bin"
  fi
  MANAGER="pipx"
else
  MANAGER="pip"
fi

CLI_TOOLS=(ruff black pytest mypy uv)
LIBRARIES=(requests)

# --- Install CLI tools (via pipx or pip) ---
for tool in "${CLI_TOOLS[@]}"; do
  echo "Installing or upgrading $tool..."
  if [ "$MANAGER" = "pipx" ]; then
    if pipx list | grep -q "$tool"; then
      pipx upgrade "$tool" >/dev/null
    else
      pipx install "$tool" >/dev/null
    fi
  else
    $PYTHON -m pip install --upgrade "$tool" >/dev/null
  fi
done

# --- Handle libraries safely ---
echo "Installing Python libraries (in venv if needed)..."
VENV_DIR="$HOME/.venvs/dev-setup"
mkdir -p "$VENV_DIR"

if $PYTHON -m venv "$VENV_DIR" >/dev/null 2>&1; then
  source "$VENV_DIR/bin/activate"
  for lib in "${LIBRARIES[@]}"; do
    echo "Installing $lib in isolated venv..."
    pip install --upgrade "$lib" >/dev/null
  done
  deactivate
  echo "Libraries installed in virtual environment at $VENV_DIR"
else
  echo "Venv creation failed, trying user install..."
  for lib in "${LIBRARIES[@]}"; do
    $PYTHON -m pip install --user --break-system-packages "$lib" >/dev/null 2>&1 || true
  done
fi

if [ "$MANAGER" = "pipx" ]; then
  export PATH="$HOME/.local/bin:$PATH"
  BLACK_EXE=$(command -v black || echo "$HOME/.local/bin/black")
  MYPY_EXE=$(command -v mypy || echo "$HOME/.local/bin/mypy")
else
  BLACK_EXE=$(which black || true)
  MYPY_EXE=$(which mypy || true)
fi

# --- VSCode presence check ---
EXT_DIR="$HOME/Library/Application Support/Code"
if [ ! -d "$EXT_DIR" ]; then
  echo "VSCode not detected (Cursor installs separately). Skipping setup."
  exit 0
fi

# --- VSCode extensions ---
EXTENSIONS=(
  # Core Python stack
  ms-python.python
  ms-python.black-formatter
  charliermarsh.ruff
  ms-python.vscode-pylance
  ms-python.mypy-type-checker
  LittleFoxTeam.vscode-python-test-adapter
  ms-toolsai.jupyter
  ms-toolsai.datawrangler
  KevinRose.vsc-python-indent

  # DevOps / CI / Docker
  GitHub.vscode-github-actions
  ms-azuretools.vscode-docker
  redhat.vscode-yaml
  foxundermoon.shell-format

  # Git / collaboration
  eamodio.gitlens
  GitHub.vscode-pull-request-github   # <-- актуальный ID
  mhutchie.git-graph

  # Utils / Style / Docs
  streetsidesoftware.code-spell-checker
  streetsidesoftware.code-spell-checker-russian
  aaron-bond.better-comments
  oderwat.indent-rainbow
  usernamehw.errorlens
  Gruntfuggly.todo-tree
  yzhang.markdown-all-in-one
  formulahendry.code-runner
  wmaurer.change-case
)

echo "Installing VSCode extensions..."
for ext in "${EXTENSIONS[@]}"; do
  if ! "$CODE_CLI" --list-extensions | grep -q "$ext"; then
    "$CODE_CLI" --install-extension "$ext" >/dev/null
    echo "Installed: $ext"
  else
    echo "Already installed: $ext"
  fi
done

# --- VSCode settings.json ---
SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
SETTINGS_PATH="$SETTINGS_DIR/settings.json"
mkdir -p "$SETTINGS_DIR"

cat >"$SETTINGS_PATH" <<EOF
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

  "python.defaultInterpreterPath": "$PYTHON",
  "black-formatter.importStrategy": "fromEnvironment",
  "black-formatter.path": ["$BLACK_EXE"],

  "python.testing.pytestEnabled": true,
  "python.testing.unittestEnabled": false,
  "python.testing.autoTestDiscoverOnSaveEnabled": true,

  "mypy-type-checker.enabled": true,
  "mypy-type-checker.path": ["$MYPY_EXE"],

  "python.languageServer": "Pylance",
  "python.analysis.typeCheckingMode": "basic",
  "python.analysis.diagnosticMode": "workspace",

  "cSpell.language": "en,ru",
  "cSpell.enableFiletypes": ["python","json","yaml","markdown"],
  "cSpell.ignoreWords": ["pytest","asyncio","uvicorn","FastAPI","Pydantic"],

  "chat.disableAIFeatures": true,
  "chat.commandCenter.enabled": false
}
EOF
echo "VSCode settings.json updated at $SETTINGS_PATH"

# --- Global pyproject.toml ---
PYPROJECT_PATH="$HOME/pyproject.toml"
cat >"$PYPROJECT_PATH" <<'EOF'
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
EOF
echo "pyproject.toml created at $PYPROJECT_PATH"

echo "Setup complete. Restart VSCode to apply all settings."
