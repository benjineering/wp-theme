#!/usr/bin/env ruby

require 'byebug'

require 'fileutils'
require 'open-uri'
require 'optparse'
require 'progressbar'
require 'tempfile'
require 'zip'

WP_URL = 'https://wordpress.org/latest.zip'
THEME_URL = 'https://codeload.github.com/toddmotto/html5blank/zip/stable'

WP_ROOT_DIR = 'wordpress'

DEFAULT_DIRECTORY = 'Wordpress'
DEFAULT_THEME = 'Custom Theme'

@opts = {
  dir: DEFAULT_DIRECTORY,
  theme: DEFAULT_THEME
}


def download_and_unzip(url, path)
  raise "#{path} is a file" if File.file?(path)

  if Dir.exists?(path) && !Dir[File.join(path, '*')].empty?
    raise "#{path} exists and isn't empty"
  end

  @tempfile = Tempfile.new('wp_theme_zip')
  @tempfile.write(URI.parse(url).read)
  @tempfile.close

  Zip::File.open(@tempfile.path) do |zip|
    zip.each do |entry|
      name_parts = entry.name.split(File::SEPARATOR)
      name_parts.shift
      entry_name = name_parts.join(File::SEPARATOR)
      filepath = File.join(path, entry_name)
      entry.extract(filepath)
    end
  end

ensure
  unless @tempfile.nil?
    @tempfile.close!
  end
end


def camelize(str)
  str.gsub!(/\s+|-/, '_')
  str.gsub!(/[^a-zA-Z0-9_]/, '')
  str.downcase
end


OptionParser.new do |opts|
  opts.banner = 'Usage: wp_theme.rb [options]'

  opts.on('-dDIR', '--directory=DIR', 'Wordpress directory name') do |d|
    @opts[:dir] = d
  end

  opts.on('-tTHEME', '--theme=THEME', 'New theme name') do |t|
    @opts[:theme] = t
  end
end.parse!

@opts[:dir] = File.expand_path(@opts[:dir])
@theme_dir = File.join(@opts[:dir], 'wp-content', 'themes', @opts[:theme])

download_and_unzip(WP_URL, @opts[:dir])
download_and_unzip(THEME_URL, @theme_dir)

camelized_theme = camelize(@opts[:theme])

Dir[File.join(@theme_dir, '**', '*.{php,css,js}')].each do |path|
  text = File.read(path)

  text.gsub!(/html5_?blank/, camelized_theme)
  text.gsub!(/html5wp/, camelized_theme + '_wp')
  text.gsub!(/html5_/, camelized_theme + '_')
  text.gsub!(/html5/, camelized_theme)
  text.gsub!(/HTML5 Blank/, @opts[:theme])

  File.open(path, 'wb') { |file| file.write(text) }
end
