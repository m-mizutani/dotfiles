#!/bin/sh
# Claude Code status line: model, context %, tokens, estimated cost

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# Estimate cost based on claude-sonnet-4 pricing (input: $3/1M, output: $15/1M)
cost=$(echo "$total_in $total_out" | awk '{
  input_cost  = $1 / 1000000 * 3.00
  output_cost = $2 / 1000000 * 15.00
  total = input_cost + output_cost
  printf "%.4f", total
}')

if [ -n "$used_pct" ]; then
  ctx_str=$(printf "ctx:%.1f%%" "$used_pct")
else
  ctx_str="ctx:--"
fi

in_k=$(echo "$total_in"  | awk '{printf "%.1fk", $1/1000}')
out_k=$(echo "$total_out" | awk '{printf "%.1fk", $1/1000}')

# Rate limit usage
rl_5h=$(echo "$input"  | jq -r '.rate_limits.five_hour.used_percentage  // empty')
rl_7d=$(echo "$input"  | jq -r '.rate_limits.seven_day.used_percentage  // empty')

if [ -n "$rl_5h" ]; then
  rl_5h_str=$(printf "5h:%.1f%%" "$rl_5h")
else
  rl_5h_str="5h:--"
fi

if [ -n "$rl_7d" ]; then
  rl_7d_str=$(printf "7d:%.1f%%" "$rl_7d")
else
  rl_7d_str="7d:--"
fi

printf "%s | %s | in:%s out:%s | \$%s | %s %s" "$model" "$ctx_str" "$in_k" "$out_k" "$cost" "$rl_5h_str" "$rl_7d_str"
