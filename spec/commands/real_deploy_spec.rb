require 'spec_helper'
require 'command_helper'
require 'fileutils'
require 'tmpdir'

describe "Invoking the 'mina' command in a project", :ssh => true do
  before :each do
    @path = Dir.mktmpdir
    Dir.chdir @path

    FileUtils.mkdir_p './config'
    FileUtils.cp root('test_env/config/deploy.rb'), './config/deploy.rb'
    FileUtils.rm_rf './deploy'
    FileUtils.mkdir_p './deploy'
  end

  # after :each do
  #   FileUtils.rm_rf @path
  # end

  it 'should set up and deploy fine' do
    print "[setup]" if ENV['verbose']
    mina 'setup', '--verbose'
    expect(File.directory?('deploy')).to be_true
    expect(File.directory?('deploy/releases')).to be_true
    expect(File.directory?('deploy/shared')).to be_true
    expect(File.exists?('deploy/last_version')).to be_false
    expect(File.exists?('deploy/deploy.lock')).to be_false

    print "[deploy 1]" if ENV['verbose']
    mina 'deploy', '--verbose'
    expect(stdout).to include "-----> Creating a temporary build path"
    expect(stdout).to include "rm -rf .git"
    expect(stdout).to include "mkdir -p"
    expect(File.exists?('deploy/last_version')).to be_true
    expect(File.exists?('deploy/deploy.lock')).to be_false
    expect(File.directory?('deploy/releases')).to be_true
    expect(File.directory?('deploy/releases/1')).to be_true
    expect(File.exists?('deploy/releases/1/README.md')).to be_true
    expect(File.directory?('deploy/releases/2')).to be_false
    expect(File.exists?('deploy/current')).to be_true
    expect(File.read('deploy/last_version').strip).to eq('1')
    expect(File.exists?('deploy/current/tmp/restart.txt')).to be_true

    # And again, to test out sequential versions and stuff
    print "[deploy 2]" if ENV['verbose']
    mina 'deploy'
    expect(stdout).not_to include "rm -rf .git"
    expect(stdout).not_to include "mkdir -p"
    expect(File.directory?('deploy/releases/2')).to be_true
    expect(File.read('deploy/last_version').strip).to eq('2')
  end
end
