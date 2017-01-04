class GobjectIntrospection < Formula
  desc "Generate introspection data for GObject libraries"
  homepage "https://live.gnome.org/GObjectIntrospection"
  url "https://download.gnome.org/sources/gobject-introspection/1.50/gobject-introspection-1.50.0.tar.xz"
  sha256 "1c6597c666f543c70ef3d7c893ab052968afae620efdc080c36657f4226337c5"

  bottle do
    sha256 "c50540846431e361498c8912c8b6852c1547f94458cb080cad9754ac9ffa4129" => :sierra
    sha256 "2999c2c6259c37a49600acd02f7330841756ee71df39fd8e8a88e406881a95f7" => :el_capitan
    sha256 "cb851182a1a2c6bdd29ed88b8f186fc7f2453e0b3cbf2c36409e80c00c3a100c" => :yosemite
  end

  head do
    url "git://git.gnome.org/gobject-introspection"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  option :universal

  depends_on "pkg-config" => :run
  depends_on "glib"
  depends_on "cairo"
  depends_on "libffi"
  depends_on "python"

  resource "tutorial" do
    url "https://gist.github.com/7a0023656ccfe309337a.git",
        :revision => "499ac89f8a9ad17d250e907f74912159ea216416"
  end

  def install
    if build.head?
      ENV["NOCONFIGURE"] = "yes"
      system "./autogen.sh"
    end

    ENV["GI_SCANNER_DISABLE_CACHE"] = "true"
    ENV.universal_binary if build.universal?
    inreplace "giscanner/transformer.py", "/usr/share", "#{HOMEBREW_PREFIX}/share"
    inreplace "configure" do |s|
      s.change_make_var! "GOBJECT_INTROSPECTION_LIBDIR", "#{HOMEBREW_PREFIX}/lib"
    end

    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}", "PYTHON=python"
    system "make"
    system "make", "install"
  end

  test do
    ENV.prepend_path "PKG_CONFIG_PATH", Formula["libffi"].opt_lib/"pkgconfig"
    resource("tutorial").stage testpath
    system "make"
    assert (testpath/"Tut-0.1.typelib").exist?
  end
end
