module VanHelsing
  module Helpers
    # Invokes another Rake task.
    def invoke(task)
      Rake::Task[task.to_sym].invoke
    end

    # Wraps the things inside it in a deploy script.
    def deploy(&blk)
      validate_set :deploy_to

      set :current_version, Time.now.strftime("%Y-%m-%d--%H-%m-%S")
      set :release_path, "#{deploy_to}/releases/#{current_version}"
      set :current_path, "#{deploy_to}/current"
      set :lock_file, "#{deploy_to}/deploy.lock"

      old, @codes = @codes, nil
      yield
      new_code, @codes = @codes, old

      prepare = new_code[:default].map { |s| "(\n#{indent 2, s}\n)" }.join(" && ")
      restart = new_code[:restart].map { |s| "(\n#{indent 2, s}\n)" }.join(" && ")
      clean   = new_code[:clean].map { |s| "(\n#{indent 2, s}\n)" }.join(" && ")

      require 'erb'
      erb = ERB.new(File.read(VanHelsing.root_path('data/deploy.sh.erb')))
      code = erb.result(binding)
        
      queue code
    end

    # Deploys and runs.
    def deploy!(&blk)
      deploy &blk
      run!
    end

    # SSHs into the host and runs the code that has been queued.
    def run!
      validate_set :host

      args = settings.host
      args = "#{settings.user}@#{args}" if settings.user
      args << " -i #{settings.identity_file}" if settings.identity_file

      code = [
        '( cat <<DEPLOY_EOF',
        indent(2, codes[:default].join("\n").gsub('$', '\$').strip),
        "DEPLOY_EOF",
        ") | ssh #{args} -- bash -"
      ].join("\n")

      puts code
    end

    # Queues code to be ran.
    # To get the things that have been queued, use codes[:default]
    def queue(code)
      codes
      codes[@code_block] << code.gsub(/^ */, '')
    end

    # Returns a hash of the code blocks where commands have been queued.
    #
    #     > codes
    #     #=> { :default => [ 'echo', 'sudo restart', ... ] }
    #
    def codes
      @codes ||= begin
        @code_block = :default
        Hash.new { |h, k| h[k] = Array.new }
      end
    end

    def to(name, &blk)
      old, @code_block = @code_block, name
      yield
      @code_block = old
    end

    def set(key, value)
      settings.send :"#{key}=", value
    end

    def settings
      @settings ||= OpenStruct.new
    end

    def method_missing(meth, *args, &blk)
      @settings.send meth, *args
    end

    def indent(count, str)
      str.gsub(/^/, " "*count)
    end

    def error(str)
      $stderr.write "#{str}\n"
    end

    def validate_set(*settings)
      settings.each do |key|
        unless @settings.send(key)
          error "ERROR: You must set the :#{key} setting."
          exit 1
        end
      end
    end
  end
end