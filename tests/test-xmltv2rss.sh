#!/bin/sh

# Run CLI program tests
#
# All tests are successful when both:
# - the standard output and standard error are empty and
# - the exit code is 0

input_dir=input
expected_dir=output

# Temp files
output_file="$(mktemp --dry-run "${TMPDIR:-/tmp}/${0##*/}.XXXXXX")"
output_file_tmp="$output_file-output"
expected_file_tmp="$output_file-expected"
trap 'rm -f "$output_file" "$output_file_tmp" "$expected_file_tmp"' EXIT

cd "${0%/*}" || exit

ret=0
for input_file in "$input_dir"/*.xml; do
  expected_file="$expected_dir/${input_file##*/}"

  # Compare in the same timezone (TZ=UTC) to avoid unnecessary diff output

  # Set the expected datetime for <pubDate/>
  #TZ=UTC touch -m --date='Thu, 18 Apr 2024 12:00:00 +0000' "$input_file"
  TZ=UTC touch -m -t 202404181200.00 "$input_file"

  # Run test
  TZ=UTC ../xmltv2rss.py "$input_file" >"$output_file" || exit 1

  # Avoid diff output "No newline at end of file"
  echo >>"$output_file"

  # Diff the result
  #diff --unified=0 "$expected_file" "$output_file" || ret=1

  # Diff the result but ignore the <lastBuildDate/> line
  sed '/lastBuildDate/d;' "$output_file" >"$output_file_tmp"
  sed '/lastBuildDate/d;' "$expected_file" >"$expected_file_tmp"
  msg="$(diff --unified=0 "$expected_file_tmp" "$output_file_tmp")" || ret=1
  if [ -n "$msg" ]; then
    printf '==> %s\n' "$input_file"
    printf '%s\n' "$msg"
  fi
done

exit $ret
