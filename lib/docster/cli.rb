require 'thor'
require 'bundler'
require 'docster/doc_generator'

module Docster
  class CLI < Thor
    
    desc 'generate', "Generate merged sdoc documentation for all :default and :development gems in this project"
    method_option :groups, :default => ['default', 'development'], :type => :array, :aliases => '-g'
    method_option :name, :default => Bundler.default_gemfile.dirname.split.last.to_s, :type => :string, :aliases => '-n'
    method_option :ruby_version, :default => "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}", :type => :string, :aliases => '-r', :desc => 'Ruby version to include (defaults to this Ruby)', :banner => '(VERSION)-p(PATCHLEVEL)'
    method_option :without_ruby, :default => false, :type => :boolean, :desc => 'Generate documentation without Ruby docs'
    def generate
      DocGenerator.generate! options.name, options.groups, (options.without_ruby ? nil : options.ruby_version)
    end

  end
end