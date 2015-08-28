require 'puppet/application/spec'

describe Puppet::Application::Spec do

  describe ".run_command" do
    # TODO
  end

  describe ".process_spec_directory" do
    before do
      allow(subject).to receive(:process_spec).and_return(:stub_result)
      allow(Dir).to receive(:glob).and_return([
        :stub_spec1,
        :stub_spec2,
        :stub_spec3,
      ])
    end

    it "should evaluate the specdir" do
      subject.process_spec_directory('stub_path')
      expect(Dir).to have_received(:glob).with('stub_path/**/*_spec.pp')
    end

    it "should process each spec" do
      subject.process_spec_directory('stub_path')
      expect(subject).to have_received(:process_spec).once.with(:stub_spec1)
      expect(subject).to have_received(:process_spec).once.with(:stub_spec2)
      expect(subject).to have_received(:process_spec).once.with(:stub_spec3)
    end
  end

  describe ".process_spec" do
    before do
      allow(subject).to receive(:catalog).and_return(:stub_catalog)
      allow(subject).to receive(:notify_compiled)
      allow(subject).to receive(:evaluate)
    end

    it "should compile the catalog" do
      subject.process_spec(:stub_path)
      expect(subject).to have_received(:catalog).with(:stub_path)
    end

    it "should print a notification" do
      subject.process_spec(:stub_path)
      expect(subject).to have_received(:notify_compiled)
    end

    it "should visit the catalog" do
      subject.process_spec(:stub_path)
      expect(subject).to have_received(:evaluate).with(:stub_catalog)
    end
  end

  describe ".catalog" do
    let(:the_node) { double('node', :name => :stub_name) }
    let(:the_catalog) { double(:to_ral => nil) }
    let(:the_indirection) { double('indirection', :find => the_catalog) }

    before do
      allow(Puppet::Test::TestHelper).to receive(:before_each_test)
      allow(Puppet::Test::TestHelper).to receive(:after_each_test)
      allow(Puppet).to receive(:[]=)
      allow(Puppet::Node).to receive(:new).and_return(the_node)
      allow(Puppet::Resource::Catalog).to receive(:indirection).and_return(the_indirection)
      allow(File).to receive(:read).and_return(:stub_file)
      allow(subject).to receive(:get_modulepath).and_return(:the_modulepath)
      allow(subject).to receive(:link_module)
    end

    it "should initialize Puppet" do
      subject.catalog(:stub_path)
      expect(Puppet::Test::TestHelper).to have_received(:before_each_test)
    end

    it "should read the spec manifest" do
      subject.catalog(:stub_path)
      expect(File).to have_received(:read).with(:stub_path)
    end

    it "should give Puppet the spec manifest" do
      subject.catalog(:stub_path)
      expect(Puppet).to have_received(:[]=).with(:code, :stub_file)
    end

    it "should calculate the modulepath" do
      subject.catalog(:stub_path)
      expect(subject).to have_received(:get_modulepath).with(the_node)
    end

    it "should create the module symlink" do
      subject.catalog(:stub_path)
      expect(subject).to have_received(:link_module)
    end

    it "should compile the catalog" do
      subject.catalog(:stub_path)
      expect(the_indirection).to have_received(:find).with(:stub_name, :use_node => the_node)
    end

    it "should finalize the catalog" do
      subject.catalog(:stub_path)
      expect(the_catalog).to have_received(:to_ral)
    end

    it "should clean up the test" do
      subject.catalog(:stub_path)
      expect(Puppet::Test::TestHelper).to have_received(:after_each_test)
    end

    it "should return the catalog" do
      expect(subject.catalog(:stub_path)).to eq(the_catalog)
    end
  end

  describe ".evaluate" do
    let(:the_resources) {[
      double(:[] => :stub,
             :[]= => nil,
             :type => 'Assertion',
             :resource_type => the_type)
    ]}
    let(:the_type) { double(:assert => :stub_assertion) }
    let(:the_catalog) { double(:resources => the_resources, :resource => :stub_resource) }

    it "should check the type of each resource" do
      subject.evaluate(the_catalog)
      expect(the_resources[0]).to have_received(:type)
    end

    context "when the resource is an assertion" do

      it "should get its subject from the catalog" do
        subject.evaluate(the_catalog)
        expect(the_catalog).to have_received(:resource).with('stub')
      end

      it "should assert on the resource" do
        subject.evaluate(the_catalog)
        expect(the_type).to have_received(:assert).with(the_resources[0])
      end
    end

    context "when the resource is not an assertion" do
      let(:the_resources) {[ double(:[] => :stub, :[]= => nil, :type => :nope) ]}

      it "should not assert" do
        subject.evaluate(the_catalog)
        expect(the_type).to_not have_received(:assert)
      end
    end

    it "should return the assertion results" do
      expect(subject.evaluate(the_catalog)).to eq([:stub_assertion])
    end
  end

  describe ".assert" do
    # TODO
  end

  describe ".print_results" do
    # TODO
  end

  describe ".notify_compiled" do
    before do
      allow(subject).to receive(:print)
    end

    it "should print a green period" do
      subject.notify_compiled
      expect(subject).to have_received(:print).with("\e[0;32m.\e[0m")
    end
  end

  describe ".get_modulepath" do
    context "when given a node object" do
      let(:the_environment) { double('environment', :full_modulepath => [:stub_path, 2]) }
      let(:the_node) { double('node', :environment => the_environment) }

      it "should return the correct modulepath" do
        expect(subject.get_modulepath(the_node)).to eq(:stub_path)
      end
    end
  end

  describe ".link_module" do
    before do
      allow(Dir).to receive(:pwd).and_return(:stub_pwd)
      allow(Dir).to receive(:exist?)
      allow(File).to receive(:symlink?)
      allow(File).to receive(:basename).and_return(:stub_name)
      allow(File).to receive(:join).and_return(:stub_sympath)
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:ln_s)
    end

    it "should get the module's directory" do
      subject.link_module(:stub_module)
      expect(Dir).to have_received(:pwd)
    end

    it "should get the module's name" do
      subject.link_module(:stub_module)
      expect(File).to have_received(:basename).with(:stub_pwd)
    end

    it "should get the symlink's path" do
      subject.link_module(:stub_module)
      expect(File).to have_received(:join).with(:stub_module, :stub_name)
    end

    it "should check if the modulepath exists" do
      subject.link_module(:stub_module)
      expect(Dir).to have_received(:exist?).with(:stub_module)
    end

    context "when the modulepath exists" do
      before do
        allow(Dir).to receive(:exist?).and_return(true)
      end
      it "should not create the modulepath directory" do
        subject.link_module(:stub_module)
        expect(FileUtils).to_not have_received(:mkdir_p)
      end
    end

    context "when the modulepath does not exist" do
      before do
        allow(Dir).to receive(:exist?).and_return(false)
      end
      it "should create the modulepath directory" do
        subject.link_module(:stub_module)
        expect(FileUtils).to have_received(:mkdir_p).with(:stub_module)
      end
    end

    it "should check if the symlink exists" do
      subject.link_module(:stub_module)
      expect(File).to have_received(:symlink?).with(:stub_sympath)
    end

    context "when the symlink does exist" do
      before do
        allow(File).to receive(:symlink?).and_return(true)
      end
      it "should not create the symlink" do
        subject.link_module(:stub_module)
        expect(FileUtils).to_not have_received(:ln_s)
      end
    end

    context "when the symlink does not exist" do
      before do
        allow(File).to receive(:symlink?).and_return(false)
      end
      it "should not create the symlink" do
        subject.link_module(:stub_module)
        expect(FileUtils).to have_received(:ln_s).with(:stub_pwd, :stub_sympath)
      end
    end
  end

  describe ".specdir" do
    before do
      allow(Dir).to receive(:pwd).and_return(:stub_pwd)
      allow(Dir).to receive(:exist?).and_return(true)
      allow(File).to receive(:join).and_return(:stub_specdir)
    end

    it "should get the pwd" do
      subject.specdir
      expect(Dir).to have_received(:pwd)
    end

    it "should parse the specdir" do
      subject.specdir
      expect(File).to have_received(:join).with(:stub_pwd, 'spec')
    end

    context "when the CWD contains a spec directory" do
      before { allow(Dir).to receive(:exist?).and_return(true) }

      it "should return the path to the specdir" do
        expect(subject.specdir).to eq(:stub_specdir)
      end

      it "should return the specdir" do
        expect(subject.specdir).to eq(:stub_specdir)
      end
    end

    context "when the CWD does not contain a spec directory" do
      before { allow(Dir).to receive(:exist?).and_return(false) }

      it "should raise an error" do
        expect{subject.specdir}.to raise_error(
          'No spec directory was found under the CWD. You can optionally specifiy one with --specdir'
        )
      end
    end
  end

end
