#!/bin/sh

# Run CLI program tests

input_dir=input
expected_dir=output

output_file="$(mktemp --dry-run "${TMPDIR:-/tmp}/${0##*/}.XXXXXX")"
trap 'rm -f "$output_file"' EXIT

cd "${0%/*}" || exit

ret=0
for input_file in "$input_dir"/*.xml; do
  expected_file="$expected_dir/${input_file##*/}"

  # need to compare in the same timezone, otherwise we'll get many diff's
  TZ=UTC ../xmltv2rss.py "$input_file" >"$output_file" || exit 1

  #diff --unified=0 "$expected_file" "$output_file" || ret=1

  # Diff the result but ignore the <lastBuildDate/> line
  output_file_tmp="$output_file-output"
  expected_file_tmp="$output_file-expected"
  sed '/lastBuildDate/d' "$output_file" >"$output_file_tmp"
  sed '/lastBuildDate/d' "$expected_file" >"$expected_file_tmp"
  msg="$(diff --unified=0 "$expected_file_tmp" "$output_file_tmp")" || ret=1
  if [ -n "$msg" ]; then
    printf '==> %s\n' "$input_file"
    printf '%s\n' "$msg"
  fi
  rm "$output_file_tmp" "$expected_file_tmp"
done

exit $ret
