require 'spec_helper'

describe 'curator' do
  context 'supported operating systems' do
    ['Debian', 'RedHat'].each do |osfamily|
      let(:facts) {{
        :osfamily => osfamily,
        :lsbdistid => 'Ubuntu',
        :lsbdistcodename => 'trusty',
        :lsbdistrelease => '14.04',
        :puppetversion   => Puppet.version,
      }}

      describe "curator class without any parameters on #{osfamily}" do

        it { should compile.with_all_deps }

        it { should contain_class('curator') }
        it { should contain_class('curator::params') }
        it { should contain_class('curator::install') }

        it { should contain_package('python-pip')\
          .with_ensure('present')\
          .that_comes_before('Package[elasticsearch-curator]')
        }
        it { should contain_package('elasticsearch-curator').with_provider('pip') }
      end

      describe "curator with a delete indices cron on #{osfamily}" do
        let(:params) {{
          :crons => {
             'puppet-report' => {
                'command'     => 'delete',
                'parameters'  => '--time-unit days --older-than 14 --timestring \\%Y.\\%m.\\%d --prefix puppet-report-',
            }
          }
        }}

        it { should compile.with_all_deps }
        it { should contain_curator__cron('puppet-report')\
          .with_command('delete')\
          .with_parameters('--time-unit days --older-than 14 --timestring \\%Y.\\%m.\\%d --prefix puppet-report-')
        }
        it { is_expected.to contain_cron('cron_curator_puppet-report') }
      end
    end
  end

  context 'unsupported operating system' do
    describe 'curator class without any parameters on Solaris/Nexenta' do
      let(:facts) {{
        :osfamily        => 'Solaris',
        :operatingsystem => 'Nexenta',
      }}

      it { expect { should contain_package('curator') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
end
