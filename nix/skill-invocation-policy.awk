# Sets a skill's invocation policy in its SKILL.md frontmatter.
#   -v policy=disable  ensures `disable-model-invocation: true`
#   -v policy=auto     removes the key
# A file without frontmatter passes through unchanged.

NR == 1 && $0 == "---" { in_frontmatter = 1; print; next }

in_frontmatter && $0 == "---" {
  if (policy == "disable" && !seen) print "disable-model-invocation: true"
  in_frontmatter = 0
  print
  next
}

in_frontmatter && /^disable-model-invocation:/ {
  seen = 1
  if (policy == "disable") print "disable-model-invocation: true"
  next
}

{ print }
