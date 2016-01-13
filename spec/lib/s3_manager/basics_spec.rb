require 'rails_spec_helper'

include Toolkits::S3Manager::BasicsToolkit

RSpec.describe S3Manager::Manager do
  let(:s3_manager) { S3Manager::Manager.new }

  describe "#client" do
    subject { s3_manager.client }

    it "builds a new S3 client" do
      expect(subject.class).to eq(Aws::S3::Client)
    end

    it "uses the correct env variables for the client" do
      expect(Aws::S3::Client).to receive(:new).with(client_attributes)
      subject
    end

    it "caches the client" do
      subject
      expect(Aws::S3::Client).not_to receive(:new)
      subject
    end
  end

  describe "#resource" do
    subject { s3_manager.resource }

    it "builds a new S3 Resource object" do
      expect(subject.class).to eq(Aws::S3::Resource)
    end

    it "caches the resource" do
      subject
      expect(Aws::S3::Resource).not_to receive(:new)
      subject
    end
  end

  describe "#bucket" do
    subject { s3_manager.bucket }

    it "builds a new s3 client" do
      expect(s3_manager).to receive(:client)
      subject
    end

    it "gets the s3 bucket from the resource" do
      expect(subject.class).to eq(Aws::S3::Bucket)
    end

    it "caches the bucket" do
      subject
      expect(s3_manager).not_to receive(:resource)
      subject
    end
  end

  describe "#bucket_name" do
    it "should be 'gradecraft-' plus the Rails env" do
      expect(s3_manager.bucket_name).to eq("gradecraft-test")
    end
  end

  describe"#object_attrs" do
    it "returns a hash of attributes for a new object" do
      allow(s3_manager).to receive(:bucket_name) { "walrus-bucket" }
      expect(s3_manager.object_attrs).to eq({ bucket: "walrus-bucket" })
    end
  end

  describe "object management" do
    let(:s3_manager) { S3Manager::Manager.new }

    before(:each) { client }

    describe "#delete_object" do
    end

    describe "#get_object" do
      subject { s3_manager.get_object(object_key) }
      let(:object_key) { "jerrys-unencrypted-hat" }
      let(:client) { s3_manager.client }
      let(:object_body) { File.new("unencrypted-jerry-was-here.doc", "w+b") }
      let(:put_object) { s3_manager.put_object(object_key, object_body) }

      before { put_object }

      let(:get_object_attrs) do
        { bucket: s3_manager.bucket_name, key: object_key }
      end

      it "should call #get_object on the client" do
        expect(client).to receive(:get_object)
        subject
      end

      it "should get an AWS Seahorse object in response" do
        expect(subject.class).to eq(Seahorse::Client::Response)
      end
      
      it "should have been successful" do
        expect(subject.successful?).to be_truthy
      end

      it "should have the correct body of the gotten object" do
        expect(client).to receive(:get_object).with(get_object_attrs)
        subject
      end

      it "should suggest that AES256 encryption was used" do
        expect(subject.server_side_encryption).to eq("AES256")
      end
    end

    describe "#put_object" do
      let(:object_key) { "jerrys-unencrypted-hat" }
      let(:client) { s3_manager.client }
      let(:object_body) { File.new("unencrypted-jerry-was-here.doc", "w+b") }
      let(:put_object) { s3_manager.put_object(object_key, object_body) }

      subject { put_object }

      it "should call #put_object on the encrypted client" do
        expect(client).to receive(:put_object)
        subject
      end

      it "should get an AWS Seahorse object in response" do
        expect(subject.class).to eq(Seahorse::Client::Response)
      end

      it "should have been successful" do
        expect(subject.successful?).to be_truthy
      end

      it "should suggest that AES256 encryption was used" do
        expect(subject.server_side_encryption).to eq("AES256")
      end
    end
  end
end
