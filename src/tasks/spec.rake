require 'rspec'
require 'rspec/core/rake_task'
require 'parallel_tests/tasks'

namespace :spec do
  namespace :integration do
    require 'integration_support/workspace'
    require 'integration_support/config_server_service'
    require 'integration_support/nginx_service'
    require 'integration_support/uaa_service'
    require 'integration_support/verify_multidigest_manager'
    require 'integration_support/gnatsd_manager'

    desc 'Run health monitor integration tests against a local sandbox'
    task health_monitor: :install_dependencies do
      run_integration_specs(tags: 'hm')
    end

    desc 'Install BOSH integration test dependencies (currently Nginx, UAA, and Config Server)'
    task :install_dependencies do
      unless ENV['SKIP_DEPS'] == 'true'
        IntegrationSupport::NginxService.install unless ENV['SKIP_NGINX'] == 'true'

        IntegrationSupport::UaaService.install unless ENV['SKIP_UAA'] == 'true'

        IntegrationSupport::ConfigServerService.install unless ENV['SKIP_CONFIG_SERVER'] == 'true'

        IntegrationSupport::VerifyMultidigestManager.install unless ENV['SKIP_VERIFY_MULTIDIGEST'] == 'true'

        IntegrationSupport::GnatsdManager.install unless ENV['SKIP_GNATSD'] == 'true'
      end

      compile_dependencies
    end

    desc 'Download BOSH Agent. Use only for local dev environment'
    task :download_bosh_agent do
      trap('INT') { exit }
      sh('rm -rf bosh-agent && git clone https://github.com/cloudfoundry/bosh-agent.git')
    end

    def run_integration_specs(tags: nil)
      IntegrationSupport::Workspace.clean
      IntegrationSupport::Workspace.uaa_service.start

      proxy_env = 'https_proxy= http_proxy='

      rspec_opts += "--tag #{tags}" if tags
      rspec_opts = "SPEC_OPTS='--format documentation #{rspec_opts}'"

      parallel_options = '--multiply-processes 0.5'
      if (num_processes = ENV.fetch('NUM_PROCESSES', nil))
        parallel_options += " -n #{num_processes}"
      end

      paths = ENV.fetch('SPEC_PATH', ['spec']).split(',').join(' ')

      command =
        "#{proxy_env} #{rspec_opts} bundle exec parallel_rspec #{parallel_options} #{paths}"

      puts command
      raise unless system(command)
    ensure
      IntegrationSupport::Workspace.uaa_service.stop
    end

    def compile_dependencies
      puts 'If this fails you may want to run rake spec:integration:download_bosh_agent'
      sh('cd bosh-agent && bin/build && cd -')
    end
  end

  desc 'Run all integration tests against a local sandbox'
  task integration: %w[spec:integration:install_dependencies] do
    run_integration_specs
  end

  desc 'Run template test unit tests (i.e. Bosh::Template::Test)'
  task :template_test_unit do # TODO _why?_ this is run as part of `spec:unit:template:parallel`
    puts 'Template test unit tests (ERB templates)'
    sh('cd bosh-template/spec/assets/template-test-release/src && rspec')
  end

  def component_spec_dirs
    @component_spec_dirs ||= Dir['*/spec']
  end

  def component_dir(component_spec_dir)
    File.dirname(component_spec_dir)
  end

  def component_symbol(component_spec_dir)
    component_dir(component_spec_dir).sub(/^bosh[_-]/, '').to_sym
  end

  namespace :unit do
    desc 'Run all release unit tests (ERB templates)'
    task :release do
      puts 'Run unit tests for the release (ERB templates)'
      sh("cd #{File.expand_path('..')} && rspec")
    end

    namespace :release do
      task :parallel do
        puts 'Run unit tests for the release (ERB templates)'
        sh("cd #{File.expand_path('..')} && parallel_rspec spec")
      end
    end

    component_spec_dirs.each do |component_spec_dir|
      desc "Run unit tests for the #{component_dir(component_spec_dir)} component"
      task component_symbol(component_spec_dir) do
        trap('INT') { exit }
        sh("cd #{File.expand_path(component_dir(component_spec_dir))} && rspec")
      end

      namespace component_symbol(component_spec_dir) do
        desc "Run parallel unit tests for the #{component_dir(component_spec_dir)} component"
        task :parallel do
          trap('INT') { exit }
          sh("cd #{File.expand_path(component_dir(component_spec_dir))} && parallel_rspec spec")
        end
      end
    end

    desc 'Run all migrations tests'
    task :migrations do
      trap('INT') { exit }
      sh("cd #{File.expand_path('bosh-director')} && rspec spec/unit/db/migrations/")
    end

    desc 'Run all unit tests in parallel'
    multitask parallel: %w[spec:unit:release:parallel] + component_spec_dirs.map{|d| "spec:unit:#{component_symbol(d)}:parallel" } do
      trap('INT') { exit }
    end
  end

  desc 'Run all unit tests'
  task unit: %w[spec:unit:release] + component_spec_dirs.map{|d| "spec:unit:#{component_symbol(d)}" }
end

desc 'Run unit and integration specs'
task spec: %w[spec:unit spec:integration]