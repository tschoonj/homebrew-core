class Graphene < Formula
  desc "Thin layer of graphic data types"
  homepage "https://ebassi.github.io/graphene/"
  url "https://download.gnome.org/sources/graphene/1.2/graphene-1.2.10.tar.xz"
  sha256 "e7b58334a91ae75b776fda987c29867710008673040fc996949933f2c5f17fdb"

  bottle do
    sha256 "fe4ea086531c7c99ac358bc5dcf7017dee230530cbb1c9ab5ff069ab16aa4f63" => :sierra
    sha256 "1a77fae74e84bbf8a5d2f49faf1a548d7aaf57fe2b85737a009143eb85bff333" => :el_capitan
    sha256 "27eca42a5917f791f1a7797575faa3a1952481ffe02295f4dcdcfc04028cd1f9" => :yosemite
    sha256 "2f648859da057200b6f056d45f4041a8e055049b5123b9ded4fdd76967f3dd28" => :mavericks
    sha256 "8072477f15c69a336a63cb86c75610ab6e1b1d11eadb9b05244a4f565abf6b79" => :mountain_lion
  end

  devel do
    url "https://download.gnome.org/sources/graphene/1.5/graphene-1.5.2.tar.xz"
    sha256 "4b2fe2c3aad43416bb520e2b3f0e1f4535b0fa722291a14904b01765afe9416f"
    depends_on "meson" => :build
    depends_on "ninja" => :build
  end

  depends_on "pkg-config" => :build
  depends_on "glib"
  depends_on "gobject-introspection"

  def install
    if build.devel?
      ENV.delete("SDKROOT")
      inreplace "src/meson.build", "'-Wl,-Bsymbolic-functions'", "" 
      mkdir "build" do
        system "meson", "--prefix=#{prefix}", "-Denable-introspection=true", "-Denable-gobject-types=true", ".."
        system "ninja"
        system "ninja", "test"
        system "ninja", "install"
      end
    else
      system "./configure", "--disable-debug",
                            "--disable-dependency-tracking",
                            "--disable-silent-rules",
                            "--prefix=#{prefix}"
      system "make"
      system "make", "check"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.c").write <<-EOS.undent
      #include <graphene-gobject.h>

      int main(int argc, char *argv[]) {
      GType type = graphene_point_get_type();
        return 0;
      }
    EOS
    gettext = Formula["gettext"]
    glib = Formula["glib"]
    flags = %W[
      -I#{gettext.opt_include}
      -I#{glib.opt_include}/glib-2.0
      -I#{glib.opt_lib}/glib-2.0/include
      -I#{include}/graphene-1.0
      -I#{lib}/graphene-1.0/include
      -L#{lib}
      -lgraphene-1.0
    ]
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
