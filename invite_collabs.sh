#!/usr/bin/env bash
# Mass-invite collaborators to a GitHub repo
# Author: Pavel Veter setup version
# Usage:
#   ./invite_collabs.sh <owner/repo> <file_with_logins> [permission]
# Example:
#   ./invite_collabs.sh pavelveter/qa-course collaborators.txt pull
# Default permission: pull (read-only)

set -euo pipefail

# Color setup
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

show_help() {
  cat <<EOF
${YELLOW}Usage:${RESET}
  $0 <owner/repo> <file_with_logins> [permission]

${YELLOW}Arguments:${RESET}
  <owner/repo>         Repository name in 'user/repo' format
  <file_with_logins>   Path to file with GitHub usernames (one per line)
  [permission]         Access level: pull | push | admin (default: pull)

${YELLOW}Examples:${RESET}
  $0 pavelveter/qa-course collaborators.txt
  $0 pavelveter/qa-course collabs.txt push
EOF
}

# If asked for help or not enough args
if [[ "${1:-}" == "--help" || $# -lt 2 ]]; then
  show_help
  exit 0
fi

REPO=$1
LIST=$2
PERMISSION=${3:-pull}  # default read-only

# Validate permission
case "$PERMISSION" in
  pull|push|admin) ;;
  *)
    echo "${RED}Error:${RESET} Invalid permission '$PERMISSION'. Use: pull | push | admin"
    exit 1
    ;;
esac

if ! command -v gh >/dev/null 2>&1; then
  echo "${RED}Error:${RESET} GitHub CLI (gh) not found. Install via:"
  echo "  brew install gh   # macOS"
  echo "  winget install GitHub.cli   # Windows"
  exit 1
fi

if [[ ! -f "$LIST" ]]; then
  echo "${RED}Error:${RESET} File '$LIST' not found."
  exit 1
fi

echo "${BLUE}Checking GitHub authentication...${RESET}"
if ! gh auth status >/dev/null 2>&1; then
  echo "${YELLOW}Not logged in.${RESET} Run: gh auth login"
  exit 1
fi

echo "${BLUE}Ensuring repository is private...${RESET}"
VISIBILITY=$(gh repo view "$REPO" --json visibility --jq .visibility 2>/dev/null || echo "unknown")
if [[ "$VISIBILITY" != "private" ]]; then
  echo "${YELLOW}Repository not private. Switching...${RESET}"
  gh repo edit "$REPO" --visibility private
else
  echo "${GREEN}Repository already private.${RESET}"
fi

echo "${BLUE}Inviting collaborators with permission=${PERMISSION}...${RESET}"
COUNT=0
FAIL=0

while read -r USER; do
  [[ -z "$USER" || "$USER" =~ ^# ]] && continue  # skip empty or commented lines
  echo -n "Inviting ${YELLOW}$USER${RESET}... "
  if gh api -X PUT \
      -H "Accept: application/vnd.github.v3+json" \
      "/repos/$REPO/collaborators/$USER" \
      -f permission="$PERMISSION" >/dev/null 2>&1; then
    echo "${GREEN}OK${RESET}"
    ((COUNT++))
  else
    echo "${RED}FAILED${RESET}"
    ((FAIL++))
  fi
done <"$LIST"

echo
echo "${GREEN}✔ Done.${RESET} Invited $COUNT collaborators successfully."
if [[ $FAIL -gt 0 ]]; then
  echo "${RED}✘ $FAIL invitations failed.${RESET} Check usernames or permissions."
fi