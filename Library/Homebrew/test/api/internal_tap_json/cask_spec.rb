# frozen_string_literal: true

RSpec.describe "Internal Tap JSON -- Cask" do
  let(:internal_tap_json) { File.read(TEST_FIXTURE_DIR/"internal_tap_json/homebrew-cask.json").chomp }
  let(:tap_git_head) { "b26c1e550a8b7eed2dcd5306ea8f3da3848258b3" }

  context "when generating JSON", :needs_macos do
    before do
      FileUtils.rm_rf CoreCaskTap.instance.path
      cp_r(TEST_FIXTURE_DIR/"internal_tap_json/homebrew-cask", Tap::TAP_DIRECTORY/"homebrew")
      allow(Cask::Cask).to receive(:generating_hash?).and_return(true)
    end

    it "creates the expected hash" do
      api_hash = CoreCaskTap.instance.to_internal_api_hash
      api_hash["tap_git_head"] = tap_git_head # tricky to mock

      expect(JSON.pretty_generate(api_hash)).to eq(internal_tap_json)
    end
  end

  context "when loading JSON" do
    before do
      ENV["HOMEBREW_INTERNAL_JSON_V3"] = "1"
      ENV.delete("HOMEBREW_NO_INSTALL_FROM_API")

      allow(Homebrew::API).to receive(:fetch_json_api_file)
        .with("internal/v3/homebrew-cask.jws.json")
        .and_return([JSON.parse(internal_tap_json), false])

      # `Tap.tap_migration_oldnames` looks for renames in every
      # tap so `CoreTap.tap_migrations` gets called and tries to
      # fetch stuff from the API. This just avoids errors.
      allow(Homebrew::API).to receive(:fetch_json_api_file)
        .with("internal/v3/homebrew-core.jws.json")
        .and_return([{ "tap_migrations" => {}, "formulae" => {}, "aliases" => {} }, false])

      # To allow `cask_names.txt` to be written to the cache.
      (HOMEBREW_CACHE/"api").mkdir

      Homebrew::API::Cask.clear_cache
    end

    it "loads cask renames" do
      expect(CoreCaskTap.instance.cask_renames).to eq({
        "ankerslicer"        => "ankermake",
        "autodesk-fusion360" => "autodesk-fusion",
        "betterdummy"        => "betterdisplay",
        "julia-lang"         => "julia",
        "smlnj-lang"         => "smlnj",
      })
    end

    it "loads tap migrations" do
      expect(CoreCaskTap.instance.tap_migrations).to eq({
        "azure-cli"  => "homebrew/core",
        "basex"      => "homebrew/core",
        "borgbackup" => "homebrew/core",
        "chronograf" => "homebrew/core",
        "consul"     => "homebrew/core",
      })
    end

    it "loads tap git head" do
      expect(Homebrew::API::Cask.tap_git_head)
        .to eq(tap_git_head)
    end

    context "when loading formulae" do
      let(:julia_metadata) do
        {
          "token"                => "julia",
          "name"                 => %w[Julia],
          "desc"                 => "Programming language for technical computing",
          "homepage"             => "https://julialang.org/",
          "version"              => "1.10.2",
          "ruby_source_path"     => "Casks/j/julia.rb",
          "ruby_source_checksum" => {
            "sha256" => "7fbf6c98c0a3b75ca8636c141f38512a899565a58518fc714e5f73c210e24449",
          },
        }
      end

      let(:smlnj_metadata) do
        {
          "token"                => "smlnj",
          "name"                 => ["Standard ML of New Jersey"],
          "desc"                 => "Compiler for the Standard ML '97 programming language",
          "homepage"             => "https://www.smlnj.org/",
          "version"              => "110.99.4",
          "ruby_source_path"     => "Casks/s/smlnj.rb",
          "ruby_source_checksum" => {
            "sha256" => "d47f46a88248272314a501741460d42a8c731030912a83ef58d3c7fd1e90034d",
          },
        }
      end

      it "loads julia" do
        julia = Cask::CaskLoader.load("julia")
        expect(julia.to_h).to include(julia_metadata)
        expect(julia.sha256).to eq("26b822154ae05f2c2b66d2b1538e1df86f1bb39967cbc9380a7f2271f5a677ce")
        expect(julia.url.to_s).to eq("https://julialang-s3.julialang.org/bin/mac/x64/1.10/julia-1.10.2-mac64.dmg")
      end

      it "loads julia from rename" do
        julia = Cask::CaskLoader.load("julia-lang")
        expect(julia.to_h).to include(**julia_metadata)
      end

      it "loads smlnj" do
        smlnj = Cask::CaskLoader.load("smlnj")
        expect(smlnj.to_h).to include(**smlnj_metadata)
        expect(smlnj.sha256).to eq("2bf858017b8ba43a70b30527290ed9fbbc81d9eaac1abeba62469d95392019a3")
        expect(smlnj.url.to_s).to eq("http://smlnj.cs.uchicago.edu/dist/working/110.99.4/smlnj-amd64-110.99.4.pkg")
      end

      it "loads smlnj from rename" do
        smlnj = Cask::CaskLoader.load("smlnj-lang")
        expect(smlnj.to_h).to include(**smlnj_metadata)
      end
    end
  end
end
