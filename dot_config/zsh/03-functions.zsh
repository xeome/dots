# Utils
0short() { curl -F"shorten=$1" https://envs.sh; }
0file()  { curl -F"file=@$1" https://envs.sh; }

zst() {
    tar cf - "$1" | pv -s "$(du -sb "$1" | awk '{print $1}')" | zstd --adapt=min=6,max=19 -T0 >"$1.tar.zst"
}

jqi() {
    jq . "$1" > "tmp_$$.json" && mv "tmp_$$.json" "$1"
}

kb() { npx kanban-cli@0.3.1 "$@"; }

# Claude Code session types. Test session: writes tests, hooks off (its new
# tests fail by design). Build session: tests and fixtures read-only, no commit.
cc-test() { claude --settings '{"disableAllHooks":true}' "$@"; }
cc-build() {
    claude --settings '{"permissions":{"deny":[
        "Edit(**/*_test.go)", "Edit(**/testdata/**)",
        "Edit(**/test_*.py)", "Edit(**/*_test.py)",
        "Edit(**/*.test.*)", "Edit(**/*.spec.*)", "Edit(**/__tests__/**)",
        "Edit(**/tests/**)", "Edit(**/test/**)", "Edit(**/fixtures/**)",
        "Bash(git commit *)"]}}' "$@"
}
