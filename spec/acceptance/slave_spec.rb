require 'spec_helper_acceptance'

describe 'jenkins::slave class' do
  include_context 'jenkins'

  context 'default parameters' do
    it 'should work with no errors' do
      pp = <<-EOS
        include ::jenkins::slave
      EOS

      apply2(pp)
    end

    if fact('systemd')
      describe file('/etc/systemd/system/jenkins-slave.service') do
        it { should be_file }
        it { should contain 'ExecStart=/home/jenkins-slave/jenkins-slave-run' }
      end
      describe file('/etc/init.d/jenkins-slave') do
        it { should_not exist }
      end
      describe service('jenkins-slave') do
        it { should be_running.under('systemd') }
      end
    else
      describe file('/etc/systemd/system/jenkins-slave.service') do
        it { should_not exist }
      end
      describe file('/etc/init.d/jenkins-slave') do
        it { should be_file }
        it { should be_mode 755 }
      end
    end

    describe file("#{$sysconfdir}/jenkins-slave") do
      it { should be_file }
      it { should be_mode 600 }
    end

    describe file('/home/jenkins-slave/swarm-client-2.2-jar-with-dependencies.jar') do
      it { should be_file }
      it { should be_mode 644 }
    end

    describe service('jenkins-slave') do
      it { should be_running }
      it { should be_enabled }
    end
  end # default parameters

  context 'parameters' do
    before(:all) do
      pp = <<-EOS
        # attempt to make the swarm client the only running 'java' process
        service { jenkins: ensure => 'stopped' }
      EOS

      apply_manifest(pp)
    end

    context 'ui_user/ui_pass' do
      it 'should work with no errors' do
        pp = <<-EOS
          class { ::jenkins::slave:
            ui_user => 'imauser',
            ui_pass => 'imapass',
          }
        EOS

        apply2(pp)
      end

      describe process('java') do
        its(:user) { should eq 'jenkins-slave' }
        its(:args) { should match /-username imauser/ }
        its(:args) { should match /-passwordEnvVariable JENKINS_PASSWORD/ }
        its(:args) { should_not match /imapass/ }
      end
    end # username/password

    context 'disable_clients_unique_id' do
      context 'true' do
        it 'should work with no errors' do
          pp = <<-EOS
            class { ::jenkins::slave:
              disable_clients_unique_id => true,
            }
          EOS

          apply2(pp)
        end

        describe process('java') do
          its(:user) { should eq 'jenkins-slave' }
          its(:args) { should match /-disableClientsUniqueId/ }
        end
      end # true

      context 'false' do
        it 'should work with no errors' do
          pp = <<-EOS
            class { ::jenkins::slave:
              disable_clients_unique_id => false,
            }
          EOS

          apply2(pp)
        end

        describe process('java') do
          its(:user) { should eq 'jenkins-slave' }
          its(:args) { should_not match /-disableClientsUniqueId/ }
        end
      end # false
    end # disable_clients_unique_id
  end # parameters
end
