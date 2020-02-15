class Geant4 < Formula
  desc "Simulation toolkit for particle transport through matter"
  homepage "https://geant4.web.cern.ch"
  url "https://geant4-data.web.cern.ch/geant4-data/releases/source/geant4.10.06.p01.tar.gz"
  version "10.6.1"
  sha256 "73459f823a20cc21ec58da491cc464aaeb771ea560f9e6c692b4efd3da795d6b"

  bottle do
    cellar :any
    sha256 "fa8d02f90cb0000c9794b1bbce358977c400b1e34c897c9847dfe79955a2d267" => :catalina
    sha256 "ff910f3a7b5d6b3c371534183d300b12ba3041a52bb3ae65e9724e726f73986b" => :mojave
    sha256 "61afcd42a08f3faad4ea26a0ebd24d6e71d83747bd3f189ccf614425736910dd" => :high_sierra
    sha256 "39dfed47c21318131cdb76fa383c527073199846b54985e2f2e65c46b05203e4" => :sierra
  end

  depends_on "cmake" => [:build, :test]
  depends_on "qt"
  depends_on "xerces-c"

  resource "G4NDL" do
    url "https://cern.ch/geant4-data/datasets/G4NDL.4.6.tar.gz"
    sha256 "9d287cf2ae0fb887a2adce801ee74fb9be21b0d166dab49bcbee9408a5145408"
  end

  resource "G4EMLOW" do
    url "https://cern.ch/geant4-data/datasets/G4EMLOW.7.9.1.tar.gz"
    sha256 "820c106e501c64c617df6c9e33a0f0a3822ffad059871930f74b8cc37f043ccb"
  end

  resource "PhotonEvaporation" do
    url "https://cern.ch/geant4-data/datasets/G4PhotonEvaporation.5.5.tar.gz"
    sha256 "5995dda126c18bd7f68861efde87b4af438c329ecbe849572031ceed8f5e76d7"
  end

  resource "RadioactiveDecay" do
    url "https://cern.ch/geant4-data/datasets/G4RadioactiveDecay.5.4.tar.gz"
    sha256 "240779da7d13f5bf0db250f472298c3804513e8aca6cae301db97f5ccdcc4a61"
  end

  resource "G4SAIDDATA" do
    url "https://cern.ch/geant4-data/datasets/G4SAIDDATA.2.0.tar.gz"
    sha256 "1d26a8e79baa71e44d5759b9f55a67e8b7ede31751316a9e9037d80090c72e91"
  end

  resource "G4PARTICLEXS" do
    url "https://cern.ch/geant4-data/datasets/G4PARTICLEXS.2.1.tar.gz"
    sha256 "094d103372bbf8780d63a11632397e72d1191dc5027f9adabaf6a43025520b41"
  end

  resource "G4ABLA" do
    url "https://cern.ch/geant4-data/datasets/G4ABLA.3.1.tar.gz"
    sha256 "7698b052b58bf1b9886beacdbd6af607adc1e099fc730ab6b21cf7f090c027ed"
  end

  resource "G4INCL" do
    url "https://cern.ch/geant4-data/datasets/G4INCL.1.0.tar.gz"
    sha256 "716161821ae9f3d0565fbf3c2cf34f4e02e3e519eb419a82236eef22c2c4367d"
  end

  resource "G4PII" do
    url "https://cern.ch/geant4-data/datasets/G4PII.1.3.tar.gz"
    sha256 "6225ad902675f4381c98c6ba25fc5a06ce87549aa979634d3d03491d6616e926"
  end

  resource "G4ENSDFSTATE" do
    url "https://cern.ch/geant4-data/datasets/G4ENSDFSTATE.2.2.tar.gz"
    sha256 "dd7e27ef62070734a4a709601f5b3bada6641b111eb7069344e4f99a01d6e0a6"
  end

  resource "RealSurface" do
    url "https://cern.ch/geant4-data/datasets/G4RealSurface.2.1.1.tar.gz"
    sha256 "90481ff97a7c3fa792b7a2a21c9ed80a40e6be386e581a39950c844b2dd06f50"
  end

  def install
    mkdir "geant-build" do
      args = std_cmake_args + %w[
        ../
        -DGEANT4_USE_GDML=ON
        -DGEANT4_BUILD_MULTITHREADED=ON
        -DGEANT4_USE_QT=ON
      ]

      system "cmake", *args
      system "make", "install"
    end

    resources.each do |r|
      (share/"Geant4-#{version}/data/#{r.name}#{r.version}").install r
    end
  end

  def caveats; <<~EOS
    Because Geant4 expects a set of environment variables for
    datafiles, you should source:
      . #{HOMEBREW_PREFIX}/bin/geant4.sh (or .csh)
    before running an application built with Geant4.
  EOS
  end

  test do
    system "cmake", share/"Geant4-#{version}/examples/basic/B1"
    system "make"
    (testpath/"test.sh").write <<~EOS
      . #{bin}/geant4.sh
      ./exampleB1 run2.mac
    EOS
    assert_match "Number of events processed : 1000",
                 shell_output("/bin/bash test.sh")
  end
end
