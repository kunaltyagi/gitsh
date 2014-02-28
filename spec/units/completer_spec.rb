require 'spec_helper'
require 'gitsh/completer'

describe Gitsh::Completer do
  let(:completer) { Gitsh::Completer.new(readline, env, internal_command) }

  let(:readline) { stub('Readline', line_buffer: input) }
  let(:env) do
    stub('Environment', {
      git_commands: %w( stage stash status add commit ),
      git_aliases: %w( adder ),
      repo_heads: %w( master my-feature v1.0 fix-v1.5 fix-v1.5.1 fix-v1.5.2)
    })
  end
  let(:internal_command) { stub('InternalCommand', commands: %w( :set :exit )) }

  context 'when completing commands' do
    let(:input) { '' }

    it 'completes commands and aliases' do
      expect(completer.call('sta')).to eq ['stage ', 'stash ', 'status ']
      expect(completer.call('ad')).to eq ['add ', 'adder ']
    end

    it 'completes internal commands' do
      expect(completer.call(':')).to eq [':set ', ':exit ']
      expect(completer.call(':s')).to eq [':set ']
    end
  end

  context 'when completing arguments' do
    let(:input) { 'checkout ' }

    it 'completes heads when a command has been entered' do
      expect(completer.call('')).to include 'master ', 'my-feature ', 'v1.0 '
      expect(completer.call('m')).to include 'master ', 'my-feature '
      expect(completer.call('m')).not_to include 'v1.0 '
    end

    it 'completes head when branch include a dot' do
      expect(completer.call('fix-v1.')).to include 'fix-v1.5 ', 'fix-v1.5.1 ', 'fix-v1.5.2 '
    end

    it 'completes heads starting with :' do
      expect(completer.call('master:m')).to include 'master:my-feature '
    end

    it 'ignores input before punctuation when completing heads' do
      expect(completer.call('mas:')).to include 'mas:master ', 'mas:my-feature '
    end

    it 'completes paths beginning with a ~ character' do
      expect(completer.call('~/')).to include "#{first_regular_file('~')} "
    end

    it 'completes paths containing .. and .' do
      project_root = File.expand_path('../../../', __FILE__)
      path = File.join(project_root, 'spec/./units/../units')

      expect(completer.call("#{path}/")).to include "#{first_regular_file(path)} "
    end
  end

  def first_regular_file(directory)
    expanded_directory = File.expand_path(directory)
    Dir["#{expanded_directory}/*"].
      find { |path| File.file?(path) }.
      sub(expanded_directory, directory)
  end
end
