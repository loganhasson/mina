# # Modules: RVM
# Adds settings and tasks for managing [RVM] installations.
#
# [rvm]: http://rvm.io
#
#     require 'mina/rvm'
#
# ## Common usage
#
#     task :environment do
#       invoke :'rvm:use[ruby-1.9.3-p125@gemset_name]'
#     end
#
#     task :deploy => :environment do
#       ...
#     end

# ## Settings

# ### rvm_path
# Sets the path to RVM.
#
# You can override this in your projects if RVM is installed in a different
# path, say, if you have a system-wide RVM install.

set_default :rvm_path, "$HOME/.rvm/scripts/rvm"

# ## Tasks

# ### rvm:use[]
# Uses a given RVM environment provided as an argument.
#
# This is usually placed in the `:environment` task.
#
#     task :environment do
#       invoke :'rvm:use[ruby-1.9.3-p125@gemset_name]'
#     end
#
task :'rvm:use', :env do |t, args|
  unless args[:env]
    print_error "Task 'rvm:use' needs an RVM environment name as an argument."
    print_error "Example: invoke :'rvm:use[ruby-1.9.2@default]'"
    die
  end

  queue %{
    echo "-----> Using RVM environment '#{args[:env]}'"
    if [[ ! -s "#{rvm_path}" ]]; then
      echo "! Ruby Version Manager not found"
      echo "! If RVM is installed, check your :rvm_path setting."
      exit 1
    fi

    source #{rvm_path}
    #{echo_cmd %{rvm use "#{args[:env]}"}} || exit 1
  }
end
