require 'bundler'
require 'colored'

module Docster
  class RubyNotFound < StandardError; end
  class SdocMergeError < StandardError; end
  class SdocError < StandardError; end
  class WgetError < StandardError; end
  class RubyExtractionError < StandardError; end
  
  class DocGenerator
    def self.generate!(project_name, groups, ruby_version)
      begin
        @@groups = groups
      
        create_docs_directory! unless Dir.exists?(docs_dir)
        create_projects_directory! unless Dir.exists?(projects_path)
      
        changes = false
        gems.each do |name, info|
          unless Dir.exists?(doc_path_for name, info[:version])
            generate_sdoc_for :type => :gem, :name => name, :version => info[:version], :path => info[:path]
            changes = true
          end
        end
      
        unless ruby_version.nil? || Dir.exists?(doc_path_for 'ruby', ruby_version)
          generate_sdoc_for :name => 'ruby', :version => ruby_version, :path => download_ruby(ruby_version)
          changes = true
        end
      
        if changes || !File.exists?(File.join(project_path_for(project_name), 'index.html'))
          FileUtils.rm_rf project_path_for project_name
          sdoc_merge project_name, ruby_version
        end
        
        `open #{File.join project_path_for(project_name), 'index.html'}`
      ensure
        cleanup!
      end
    end
    
  private
    def self.sdoc_merge(project_name, ruby_version)
      names = ruby_version ? [gem_names, 'ruby'].join(',') : gem_names
      paths = ruby_version ? doc_paths << %Q( "#{doc_path_for 'ruby', ruby_version}") : doc_paths
      
      begin
        run_command "Generating project documentation...",
          %Q(sdoc-merge --title "#{project_name}" --op "#{project_path_for project_name}" --names "#{names}" #{paths}),
          SdocMergeError
      rescue SdocMergeError => e
        # On error, remove potentially partial documentation
        FileUtils.rm_rf project_path_for(project_name)
        raise e
      end
    end
    
    def self.generate_sdoc_for(options = {})
      begin
        run_command "Generating sdoc for #{options[:name]}-#{options[:version]}...",
          %Q(sdoc -o "#{doc_path_for options[:name], options[:version]}" "#{options[:path]}"),
          SdocError
      rescue SdocError => e
        # On error, remove potentially partial documentation
        FileUtils.rm_rf doc_path_for(options[:name], options[:version])
        raise e
      end
    end
    
    def self.gems
      return @@gems if defined?(@@gems)
      
      gem_paths = {}
      Bundler.definition.specs_for(@@groups.map(&:to_sym)).each do |gem|
        gem_paths[gem.name] = { :path => gem.full_gem_path, :version => gem.version.to_s }
      end
      @@gems = gem_paths
    end
    
    def self.gem_names
      gems.keys.join(',')
    end
    
    def self.doc_paths
      '"' << gems.map{ |name, info| "#{doc_path_for name, info[:version]}" }.join('" "') << '"'
    end
    
    def self.user_docster_path
      return @@user_docster_path if defined?(@@user_docster_path)
      
      @@user_docster_path = File.join(Etc.getpwuid.dir, '.docster')
    end
    
    def self.doc_path_for(name, version)
      File.join user_docster_path, 'docs', name, version
    end
    
    def self.create_docs_directory!
      FileUtils.mkdir_p docs_dir
    end
    
    def self.create_projects_directory!
      FileUtils.mkdir_p projects_path
    end
    
    def self.docs_dir
      File.join(user_docster_path, 'docs')
    end
    
    def self.tmp_path
      path = File.join(user_docster_path, 'tmp')
      FileUtils.mkdir_p path
      path
    end
    
    def self.cleanup!
      FileUtils.rm_rf tmp_path
    end
    
    def self.projects_path
      File.join user_docster_path, 'projects'
    end
    
    def self.project_path_for(project_name)
      File.join projects_path, project_name
    end
    
    def self.download_ruby(version)
      ruby_archive = "ruby-#{version}.tar.bz2"
      archive_path = File.join tmp_path, ruby_archive
      
      run_command "Downloading ruby #{version} source from ruby-lang.org, this may take a while...",
        %Q(wget http://ftp.ruby-lang.org/pub/ruby/#{version.split('.')[0..1].join('.')}/#{ruby_archive} -O "#{archive_path}"),
        WgetError
            
      raise RubyNotFound unless File.size?(archive_path)
      
      run_command "Extracting ruby...",
        %Q(tar -xf "#{archive_path}" -C "#{tmp_path}"),
        RubyExtractionError
            
      File.join tmp_path, "ruby-#{version}"
    end
    
    def self.run_command(before_message, command, error_class)
      print before_message.yellow
      raise error_class unless system "#{command} &> /dev/null"
      puts "done!".green
    end
  end
end