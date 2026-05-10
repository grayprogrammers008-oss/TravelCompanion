/^SF:/ {
  f = substr($0, 4)
  gsub(/\\/, "/", f)
  next
}
/^LF:/ { lf = substr($0,4)+0; next }
/^LH:/ {
  lh = substr($0,4)+0
  pct = (lf > 0 ? lh * 100 / lf : 0)
  printf "%6.1f%%  %5d / %-5d  %s\n", pct, lh, lf, f
  next
}
