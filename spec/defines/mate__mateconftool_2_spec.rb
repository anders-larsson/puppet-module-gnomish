require 'spec_helper'
describe 'gnomish::mate::mateconftool_2' do
  mandatory_params = {
    value: 'value'
  }
  let(:title) { '/gnomish/rspec' }
  let(:params) { mandatory_params }

  on_supported_os.sort.each do |os, os_facts|
    describe "on #{os} with default values for parameters" do
      let(:facts) { os_facts }
      let(:params) { {} }

      it 'fail' do
        expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{(expects a value for|Must pass value to)})
      end
    end

    describe "on #{os} with value set to valid string <testing>" do
      let(:params) { mandatory_params.merge({ value: 'testing' }) }

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_exec('mateconftool-2 /gnomish/rspec').with(
          {
            'command' => 'mateconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --set \'/gnomish/rspec\' --type string \'testing\'',
            'unless'  => 'test "$(mateconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --get /gnomish/rspec 2>&1 )" == "testing"',
            'path'    => '/spec/test:/path',
          },
        )
      end
    end

    describe "on #{os} with config set to valid string <mandatory>" do
      let(:params) { mandatory_params.merge({ config: 'mandatory' }) }

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_exec('mateconftool-2 /gnomish/rspec').with(
          {
            'command' => 'mateconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --set \'/gnomish/rspec\' --type string \'value\'',
            'unless'  => 'test "$(mateconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --get /gnomish/rspec 2>&1 )" == "value"',
            'path'    => '/spec/test:/path',
          },
        )
      end
    end

    describe "on #{os} with config set to valid string </etc/rspec/gconf.xml.specific>" do
      let(:params) { mandatory_params.merge({ config: '/etc/rspec/gconf.xml.specific' }) }

      it do
        is_expected.to contain_exec('mateconftool-2 /gnomish/rspec').with(
          {
            'command' => 'mateconftool-2 --direct --config-source xml:readwrite:/etc/rspec/gconf.xml.specific --set \'/gnomish/rspec\' --type string \'value\'',
            'unless'  => 'test "$(mateconftool-2 --direct --config-source xml:readwrite:/etc/rspec/gconf.xml.specific --get /gnomish/rspec 2>&1 )" == "value"',
          },
        )
      end
    end

    describe "on #{os} with key set to valid string </rspec/testing>" do
      let(:params) { mandatory_params.merge({ key: '/rspec/testing' }) }

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_exec('mateconftool-2 /rspec/testing').with(
          {
            'command' => 'mateconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --set \'/rspec/testing\' --type string \'value\'',
            'unless'  => 'test "$(mateconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --get /rspec/testing 2>&1 )" == "value"',
          },
        )
      end
    end

    ['bool', 'int', 'float', 'string'].each do |type|
      describe "on #{os} with type set to valid string <#{type}>" do
        let(:params) { mandatory_params.merge({ type: type }) }

        it do
          is_expected.to contain_exec('mateconftool-2 /gnomish/rspec').with_command(
            "mateconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --set \'/gnomish/rspec\' --type #{type} \'value\'",
          )
        end
      end
    end

    auto_types = {
      'bool'   => ['true', true, 'false', false],
      'int'    => ['3', 3],
      'float'  => ['2.42', 2.42],
      'string' => ['string'],
    }

    auto_types.each do |type, values|
      values.each do |value|
        describe "on #{os} with type on default <auto> and value set to valid <#{value}> (as #{value.class})" do
          let(:params) { mandatory_params.merge({ value: value }) }

          it do
            is_expected.to contain_exec('mateconftool-2 /gnomish/rspec').with_command(
              "mateconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults --set \'/gnomish/rspec\' --type #{type} \'#{value}\'",
            )
          end
        end
      end
    end
  end

  describe 'variable type and content validations' do
    # The following tests are OS independent, so we only test one supported OS
    redhat = {
      supported_os: [
        {
          'operatingsystem'        => 'RedHat',
          'operatingsystemrelease' => ['7'],
        },
      ],
    }

    on_supported_os(redhat).each do |_os, os_facts|
      let(:facts) { os_facts }

      validations = {
        # shortcuts defaults/mandatory will be accepted and auto converted
        'Enum[auto, bool, int, float, string]' => {
          name:    ['type'],
          valid:   ['auto', 'bool', 'int', 'float', 'string'],
          invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, false],
          message: 'Enum\[\'auto\', \'bool\', \'float\', \'int\', \'string\'\]',
        },
        'String[1]' => {
          name:    ['key'],
          valid:   ['/rspec/testing'],
          invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, false],
          message: 'expects a String',
        },
        'Variant[Boolean, Float, Integer, String[1]]' => {
          name:    ['value'],
          valid:   [true, false, 2.42, 3, false, 'string'],
          invalid: [['array'], { 'ha' => 'sh' }],
          message: 'type Boolean, Float, Integer, or String,',
        },
        'Variant[Stdlib::Absolutepath, Enum[defaults, mandatory]' => {
          name:    ['config'],
          valid:   ['/test/ing', 'defaults', 'mandatory'],
          invalid: ['in/valid', ['array'], { 'ha' => 'sh' }, 3, 2.42, false],
          message: 'Stdlib::Absolutepath.* or Enum\[\'defaults\', \'mandatory\'\]',
        },
      }

      validations.sort.each do |type, var|
        var[:name].each do |var_name|
          var[:params] = {} if var[:params].nil?
          var[:valid].each do |valid|
            context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
              let(:params) { [mandatory_params, var[:params], { "#{var_name}": valid, }].reduce(:merge) }

              it { is_expected.to compile }
            end
          end

          var[:invalid].each do |invalid|
            context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
              let(:params) { [mandatory_params, var[:params], { "#{var_name}": invalid, }].reduce(:merge) }

              it 'fail' do
                expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{#{var[:message]}})
              end
            end
          end
        end # var[:name].each
      end # validations.sort.each
    end # describe 'variable type and content validations'
  end
end
