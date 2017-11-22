class Meson < Formula
  desc "Fast and user friendly build system"
  homepage "http://mesonbuild.com/"
  url "https://github.com/mesonbuild/meson/releases/download/0.44.0/meson-0.44.0.tar.gz"
  sha256 "50f9b12b77272ef6ab064d26b7e06667f07fa9f931e6a20942bba2216ba4281b"
  revision 1
  head "https://github.com/mesonbuild/meson.git"
  revision 1

  bottle do
    cellar :any_skip_relocation
    sha256 "ee3e0add72d372710a2e29312553a73601fdcb78153549a54160c9b0003dc64d" => :high_sierra
    sha256 "ee3e0add72d372710a2e29312553a73601fdcb78153549a54160c9b0003dc64d" => :sierra
    sha256 "ee3e0add72d372710a2e29312553a73601fdcb78153549a54160c9b0003dc64d" => :el_capitan
  end

  depends_on "python3"
  depends_on "ninja"

  patch :DATA

  def install
    version = Language::Python.major_minor_version("python3")
    ENV["PYTHONPATH"] = lib/"python#{version}/site-packages"

    system "python3", *Language::Python.setup_install_args(prefix)

    bin.env_script_all_files(libexec/"bin", :PYTHONPATH => ENV["PYTHONPATH"])
  end

  test do
    (testpath/"helloworld.c").write <<~EOS
      main() {
        puts("hi");
        return 0;
      }
    EOS
    (testpath/"meson.build").write <<~EOS
      project('hello', 'c')
      executable('hello', 'helloworld.c')
    EOS

    mkdir testpath/"build" do
      system "#{bin}/meson", ".."
      assert_predicate testpath/"build/build.ninja", :exist?
    end
  end
end

__END__
diff --git a/mesonbuild/backend/ninjabackend.py b/mesonbuild/backend/ninjabackend.py
index c633daf7..4f1dc41a 100644
--- a/mesonbuild/backend/ninjabackend.py
+++ b/mesonbuild/backend/ninjabackend.py
@@ -2341,7 +2341,7 @@ rule FORTRAN_DEP_HACK
             commands += linker.get_pic_args()
             # Add -Wl,-soname arguments on Linux, -install_name on OS X
             commands += linker.get_soname_args(target.prefix, target.name, target.suffix,
-                                               abspath, target.soversion,
+                                               abspath, target.soversion, target.ltversion,
                                                isinstance(target, build.SharedModule))
             # This is only visited when building for Windows using either GCC or Visual Studio
             if target.vs_module_defs and hasattr(linker, 'gen_vs_module_defs_args'):
diff --git a/mesonbuild/compilers/c.py b/mesonbuild/compilers/c.py
index 3f9ba5cc..03ac1e8f 100644
--- a/mesonbuild/compilers/c.py
+++ b/mesonbuild/compilers/c.py
@@ -80,7 +80,7 @@ class CCompiler(Compiler):
         # Almost every compiler uses this for disabling warnings
         return ['-w']

-    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, is_shared_module):
+    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, version, is_shared_module):
         return []

     def split_shlib_to_parts(self, fname):
diff --git a/mesonbuild/compilers/compilers.py b/mesonbuild/compilers/compilers.py
index 3f088b0f..f0abe208 100644
--- a/mesonbuild/compilers/compilers.py
+++ b/mesonbuild/compilers/compilers.py
@@ -866,7 +866,7 @@ ICC_STANDARD = 0
 ICC_OSX = 1
 ICC_WIN = 2

-def get_gcc_soname_args(gcc_type, prefix, shlib_name, suffix, path, soversion, is_shared_module):
+def get_gcc_soname_args(gcc_type, prefix, shlib_name, suffix, path, soversion, version, is_shared_module):
     if soversion is None:
         sostr = ''
     else:
@@ -877,7 +877,15 @@ def get_gcc_soname_args(gcc_type, prefix, shlib_name, suffix, path, soversion, i
     elif gcc_type == GCC_OSX:
         if is_shared_module:
             return []
-        return ['-install_name', os.path.join(path, 'lib' + shlib_name + '.dylib')]
+        args = ['-install_name', os.path.join(path, 'lib' + shlib_name + '.dylib')]
+        if version and len(version.split('.')) == 3:
+            splitted = version.split('.')
+            major = int(splitted[0])
+            minor = int(splitted[1])
+            revision = int(splitted[2])
+            args += ['-compatibility_version', '%d' % (major + minor + 1)]
+            args += ['-current_version', '%d.%d' % (major + minor + 1, revision)]
+        return args
     else:
         raise RuntimeError('Not implemented yet.')

@@ -1001,8 +1009,8 @@ class GnuCompiler:
     def split_shlib_to_parts(self, fname):
         return os.path.split(fname)[0], fname

-    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, is_shared_module):
-        return get_gcc_soname_args(self.gcc_type, prefix, shlib_name, suffix, path, soversion, is_shared_module)
+    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, version, is_shared_module):
+        return get_gcc_soname_args(self.gcc_type, prefix, shlib_name, suffix, path, soversion, version, is_shared_module)

     def get_std_shared_lib_link_args(self):
         return ['-shared']
@@ -1069,7 +1077,7 @@ class ClangCompiler:
         # so it might change semantics at any time.
         return ['-include-pch', os.path.join(pch_dir, self.get_pch_name(header))]

-    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, is_shared_module):
+    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, version, is_shared_module):
         if self.clang_type == CLANG_STANDARD:
             gcc_type = GCC_STANDARD
         elif self.clang_type == CLANG_OSX:
@@ -1078,7 +1086,7 @@ class ClangCompiler:
             gcc_type = GCC_MINGW
         else:
             raise MesonException('Unreachable code when converting clang type to gcc type.')
-        return get_gcc_soname_args(gcc_type, prefix, shlib_name, suffix, path, soversion, is_shared_module)
+        return get_gcc_soname_args(gcc_type, prefix, shlib_name, suffix, path, soversion, version, is_shared_module)

     def has_multi_arguments(self, args, env):
         myargs = ['-Werror=unknown-warning-option', '-Werror=unused-command-line-argument']
@@ -1152,7 +1160,7 @@ class IntelCompiler:
     def split_shlib_to_parts(self, fname):
         return os.path.split(fname)[0], fname

-    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, is_shared_module):
+    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, version, is_shared_module):
         if self.icc_type == ICC_STANDARD:
             gcc_type = GCC_STANDARD
         elif self.icc_type == ICC_OSX:
@@ -1161,7 +1169,7 @@ class IntelCompiler:
             gcc_type = GCC_MINGW
         else:
             raise MesonException('Unreachable code when converting icc type to gcc type.')
-        return get_gcc_soname_args(gcc_type, prefix, shlib_name, suffix, path, soversion, is_shared_module)
+        return get_gcc_soname_args(gcc_type, prefix, shlib_name, suffix, path, soversion, version, is_shared_module)

     def get_std_shared_lib_link_args(self):
         # FIXME: Don't know how icc works on OSX
diff --git a/mesonbuild/compilers/cs.py b/mesonbuild/compilers/cs.py
index b8a4d13a..40eb3768 100644
--- a/mesonbuild/compilers/cs.py
+++ b/mesonbuild/compilers/cs.py
@@ -34,7 +34,7 @@ class MonoCompiler(Compiler):
     def get_link_args(self, fname):
         return ['-r:' + fname]

-    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, is_shared_module):
+    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, version, is_shared_module):
         return []

     def get_werror_args(self):
diff --git a/mesonbuild/compilers/d.py b/mesonbuild/compilers/d.py
index 9739f288..762bb1b5 100644
--- a/mesonbuild/compilers/d.py
+++ b/mesonbuild/compilers/d.py
@@ -89,9 +89,9 @@ class DCompiler(Compiler):
     def get_std_shared_lib_link_args(self):
         return ['-shared']

-    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, is_shared_module):
+    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, version, is_shared_module):
         # FIXME: Make this work for Windows, MacOS and cross-compiling
-        return get_gcc_soname_args(GCC_STANDARD, prefix, shlib_name, suffix, path, soversion, is_shared_module)
+        return get_gcc_soname_args(GCC_STANDARD, prefix, shlib_name, suffix, path, soversion, version, is_shared_module)

     def get_feature_args(self, kwargs):
         res = []
diff --git a/mesonbuild/compilers/fortran.py b/mesonbuild/compilers/fortran.py
index 2957a7c9..ba1481a8 100644
--- a/mesonbuild/compilers/fortran.py
+++ b/mesonbuild/compilers/fortran.py
@@ -93,8 +93,8 @@ end program prog
     def split_shlib_to_parts(self, fname):
         return os.path.split(fname)[0], fname

-    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, is_shared_module):
-        return get_gcc_soname_args(self.gcc_type, prefix, shlib_name, suffix, path, soversion, is_shared_module)
+    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, version, is_shared_module):
+        return get_gcc_soname_args(self.gcc_type, prefix, shlib_name, suffix, path, soversion, version, is_shared_module)

     def get_dependency_gen_args(self, outtarget, outfile):
         # Disabled until this is fixed:
diff --git a/mesonbuild/compilers/java.py b/mesonbuild/compilers/java.py
index a8138d75..1213d189 100644
--- a/mesonbuild/compilers/java.py
+++ b/mesonbuild/compilers/java.py
@@ -25,7 +25,7 @@ class JavaCompiler(Compiler):
         self.id = 'unknown'
         self.javarunner = 'java'

-    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, is_shared_module):
+    def get_soname_args(self, prefix, shlib_name, suffix, path, soversion, version, is_shared_module):
         return []

     def get_werror_args(self):
diff --git a/mesonbuild/compilers/compilers.py b/mesonbuild/compilers/compilers.py
index f0abe208..e9fc2cf0 100644
--- a/mesonbuild/compilers/compilers.py
+++ b/mesonbuild/compilers/compilers.py
@@ -878,6 +878,11 @@ def get_gcc_soname_args(gcc_type, prefix, shlib_name, suffix, path, soversion, v
         if is_shared_module:
             return []
         args = ['-install_name', os.path.join(path, 'lib' + shlib_name + '.dylib')]
+        install_name = 'lib' + shlib_name
+        if soversion is not None:
+            install_name += '.' + soversion
+        install_name += '.dylib'
+        args = ['-install_name', os.path.join(path, install_name)]
         if version and len(version.split('.')) == 3:
             splitted = version.split('.')
             major = int(splitted[0])

