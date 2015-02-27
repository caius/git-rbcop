#!/usr/bin/env ruby

# Fuck yeah metaprogramming
f = ENV.fetch("WRAPPED_FORMATTER") { "RuboCop::Formatter::SimpleTextFormatter" }
wrapped_formatter = f.split("::").inject(Kernel) { |base, child| base.const_get(child) }

class GitDiffWrangler < wrapped_formatter
  def self.load_git_amended_files
    amended_files_json = ENV.fetch("GIT_AMENDED_FILES") { fail "GIT_AMENDED_FILES value not found" }
    JSON.parse(amended_files_json).tap {|files| files.each { |_, v| v.freeze } }.freeze
  end
  @git_amended_files = load_git_amended_files

  class << self
    attr_reader :git_amended_files
  end

  def file_finished(path, offenses)
    changed_lines = git_amended_files[path]
    filtered_offenses = offenses.select { |o| changed_lines.include?(o.line) }

    super(path, filtered_offenses)
  end

  private

  def git_amended_files
    self.class.git_amended_files
  end
end
