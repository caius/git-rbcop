#!/usr/bin/env ruby

require "strscan"
require "json"

def handle(io)
  print io.slice_before(/^diff --git/).map { |lines| handle_diff(lines) }.inject(:merge).to_json
end

def handle_diff(lines)
  path = nil
  affected_lines = []

  s = StringScanner.new(lines.join)

  if s.check_until(%r{^\+\+\+ })
    # We only care about the righthand side file
    s.scan_until(%r{^\+\+\+ })
    path = File.expand_path(s.scan(/.+$/))

    while s.scan_until(/^@@ -\d+(,\d+)? \+/)
      s.scan(/(\d+)(?:,(\d+))?/)
      i, j = s[1].to_i, s[2].to_i
      affected_lines += i.upto(i + j).to_a
    end

  elsif s.check_until(%r{^rename to })
    s.scan_until(%r{^rename to })

    path = File.expand_path(s.scan(/.+$/))
    # All the file is affected lines
    lines_in_file = IO.popen(["wc", "-l", path]).read.split[0].to_i
    affected_lines = 1.upto(lines_in_file).to_a

  else
    raise "Don't know how to handle: #{lines.join.inspect}"
  end

  return {path => affected_lines} if path
  {}
end

handle($stdin)
