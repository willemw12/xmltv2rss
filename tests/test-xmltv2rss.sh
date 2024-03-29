#!/bin/sh

# Run CLI program tests
#
# All tests are successful when both:
# - the standard output and standard error are empty and
# - the exit code is 0

input_dir=input
expected_dir=output

output_file="$(mktemp --dry-run "${TMPDIR:-/tmp}/${0##*/}.XXXXXX")"
trap 'rm -f "$output_file"' EXIT

cd "${0%/*}" || exit

ret=0
for input_file in "$input_dir"/*.xml; do
  expected_file="$expected_dir/${input_file##*/}"

  # Compare in the same timezone to avoid unnecessary diff output
  TZ=UTC ../xmltv2rss.py "$input_file" >"$output_file" || exit 1

  #diff --unified=0 "$expected_file" "$output_file" || ret=1

  # Diff the result but ignore the <lastBuildDate/> line
  # and the first <pubDate/> line (the feed's pubDate)
  output_file_tmp="$output_file-output"
  expected_file_tmp="$output_file-expected"
  sed '/lastBuildDate/d; /pubDate/{x;//!d;x}' "$output_file" >"$output_file_tmp"
  sed '/lastBuildDate/d; /pubDate/{x;//!d;x}' "$expected_file" >"$expected_file_tmp"
  msg="$(diff --unified=0 "$expected_file_tmp" "$output_file_tmp")" || ret=1
  if [ -n "$msg" ]; then
    printf '==> %s\n' "$input_file"
    printf '%s\n' "$msg"
  fi
  rm "$output_file_tmp" "$expected_file_tmp"
done

exit $ret
