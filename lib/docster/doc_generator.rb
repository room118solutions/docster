require 'bundler'

module Docster
  class DocGenerator
    def self.generate!(project_name, groups)
      @@groups = groups
      
      create_gems_directory! unless Dir.exists?(File.join(user_docster_path, 'gems'))
      
      changes = false
      gems.each do |name, info|
        unless Dir.exists?(doc_path_for name, info[:version])
          generate_sdoc_for(name, info)
          changes = true
        end
      end
      
      if changes || !File.exists?(File.join user_docster_path, project_name, 'index.html')
        FileUtils.rm_rf File.join(user_docster_path, project_name)
        sdoc_merge project_name
      end
      
      `open #{File.join user_docster_path, project_name, 'index.html'}`
    end
    
  private
    def self.sdoc_merge(project_name)
      `sdoc-merge --title "#{project_name}" --op "#{File.join user_docster_path, project_name}" --names "#{gem_names}" #{doc_paths}`
    end
    
    def self.generate_sdoc_for(name, info)
      `sdoc -o "#{doc_path_for name, info[:version]}" "#{info[:path]}"`
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
    
    def self.doc_path_for(gem_name, gem_version)
      File.join(user_docster_path, 'gems', gem_name, gem_version)
    end
    
    def self.create_gems_directory!
      FileUtils.mkdir_p File.join(user_docster_path, 'gems')
    end
  end
end