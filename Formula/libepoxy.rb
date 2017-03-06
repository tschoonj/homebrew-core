class Libepoxy < Formula
  desc "Library for handling OpenGL function pointer management"
  homepage "https://github.com/anholt/libepoxy"
  url "https://download.gnome.org/sources/libepoxy/1.4/libepoxy-1.4.1.tar.xz"
  sha256 "88c6abf5522fc29bab7d6c555fd51a855cbd9253c4315f8ea44e832baef21aa6"

  bottle do
    cellar :any
    sha256 "e475eea8fa81f14b2984da71874ec3c00c8e9edcec84e9ae15eb0df5926afec7" => :sierra
    sha256 "1f064ae908ed05131d247a67361bfc7532378b29d973e464a832e89b81d7a415" => :el_capitan
    sha256 "427431ddadd2bc8da2e970be23ea8c04e46a1e117c6cde38b22a69ea428c9bb7" => :yosemite
  end

  depends_on "pkg-config" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build

  def install
    mkdir "build" do
      system "meson", "--prefix=#{prefix}", ".."
      system "ninja"
      system "ninja", "test"
      system "ninja", "install"
    end
  end

  test do
    (testpath/"test.c").write <<-EOS.undent

      #include <epoxy/gl.h>
      #include <OpenGL/CGLContext.h>
      #include <OpenGL/CGLTypes.h>
      int main()
      {
          CGLPixelFormatAttribute attribs[] = {0};
          CGLPixelFormatObj pix;
          int npix;
          CGLContextObj ctx;

          CGLChoosePixelFormat( attribs, &pix, &npix );
          CGLCreateContext(pix, (void*)0, &ctx);

          glClear(GL_COLOR_BUFFER_BIT);
          CGLReleasePixelFormat(pix);
          CGLReleaseContext(pix);
          return 0;
      }
    EOS
    system ENV.cc, "test.c", "-lepoxy", "-framework", "OpenGL", "-o", "test"
    system "ls", "-lh", "test"
    system "file", "test"
    system "./test"
  end
end
