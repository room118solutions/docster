require 'thor'
require 'bundler'
require 'docster/doc_generator'

module Docster
  class CLI < Thor
    
    desc 'generate', "Generate merged sdoc documentation for all :default and :development gems in this project"
    method_option :groups, :default => ['default', 'development'], :type => :array, :aliases => '-g'
    method_option :name, :default => Bundler.default_gemfile.dirname.split.last.to_s, :type => :string, :aliases => '-n'
    def generate
      DocGenerator.generate! options.name, options.groups
    end
       
  end
end