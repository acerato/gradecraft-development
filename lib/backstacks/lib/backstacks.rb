require "backstacks/version"
require "builders/directory_builder"
require "builders/file_builder"

require "json"
require 'fileutils'
require "open-uri"

# steps:
# 1) parse everything into an array of objects that represent the hashes
# 2) take that array of objects and generate directories for everything
# 3) wget/fetch/curl the files for all of the created temp directories
#   -- > return some kind of error if certain files weren't created properly
# 4) begin compression for the larger directory
#   -- > return some kind of message saying that compression has started

# usage

# archive = Backstacks::Archive.new(json: archive_json, name: archive_name, max_cpu_usage: 0.2)
# archive.assemble_directories_on_disk
# archive.queue_compressed_archive

module Backstacks
  class Archive
    def initialize(options={})
      @archive_json = options[:archive_json] || []
      @archive_name = options[:archive_name] || "untitled_archive"
      @max_cpu_usage = options[:max_cpu_usage] || 0.3
      @base_path = Dir.mktmpdir # need to create a tmp directory for everythign to live in
      @file_queue = Resque.new
    end

    def build_recursive_on_disk
      @archive_json.each do |directory_json|
        Directory.new(
          directory_hash: directory_json,
          base_path: @base_path).assemble_recursive,
          file_queue: @file_queue
        ).build_recursive
      end
    end

    def archive_with_compression
    end
  end
end
