function bucketof(p,   parts, n) {
  if (p ~ /^lib\/features\//) {
    n = split(p, parts, "/")
    return "features/" parts[3]
  } else if (p ~ /^lib\/core\//) {
    n = split(p, parts, "/")
    return "core/" parts[3]
  } else if (p ~ /^lib\/shared\//) {
    n = split(p, parts, "/")
    return "shared/" parts[3]
  } else if (p ~ /^lib\//) {
    return "lib/<root>"
  } else {
    return "other"
  }
}
/^SF:/ {
  current = substr($0, 4)
  gsub(/\\/, "/", current)
  bucket = bucketof(current)
  next
}
/^LF:/ { LF[bucket] += substr($0,4)+0; next }
/^LH:/ { LH[bucket] += substr($0,4)+0; next }
END {
  printf "%-35s %8s %8s %8s\n", "MODULE", "HIT", "TOTAL", "COVER%"
  printf "%-35s %8s %8s %8s\n", "------", "---", "-----", "------"
  for (b in LF) {
    pct = (LF[b] > 0) ? (LH[b] * 100.0 / LF[b]) : 0
    printf "%-35s %8d %8d %7.1f%%\n", b, LH[b], LF[b], pct
    total_h += LH[b]; total_f += LF[b]
  }
  printf "%-35s %8s %8s %8s\n", "------", "---", "-----", "------"
  printf "%-35s %8d %8d %7.1f%%\n", "TOTAL", total_h, total_f, (total_h*100.0/total_f)
}
