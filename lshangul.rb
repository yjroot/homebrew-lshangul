class Lshangul < Formula
  homepage "https://www.gnu.org/software/coreutils"
  url "http://ftpmirror.gnu.org/coreutils/coreutils-8.23.tar.xz"
  mirror "https://ftp.gnu.org/gnu/coreutils/coreutils-8.23.tar.xz"
  sha256 "ec43ca5bcfc62242accb46b7f121f6b684ee21ecd7d075059bf650ff9e37b82d"
  revision 1

  # Patch adapted from upstream commits:
  # http://git.savannah.gnu.org/gitweb/?p=coreutils.git;a=commitdiff;h=6f9b018
  # http://git.savannah.gnu.org/gitweb/?p=coreutils.git;a=commitdiff;h=3cf19b5
  stable do
    patch :DATA
  end

  head do
    url "git://git.sv.gnu.org/coreutils"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "bison" => :build
    depends_on "gettext" => :build
    depends_on "texinfo" => :build
    depends_on "xz" => :build

    resource "gnulib" do
      url "http://git.savannah.gnu.org/cgit/gnulib.git/snapshot/gnulib-0.1.tar.gz"
      sha1 "b29e165bf276ce0a0c12ec8ec1128189bd786155"
    end
  end

  def install
    if build.head?
      resource("gnulib").stage "gnulib"
      ENV["GNULIB_SRCDIR"] = "gnulib"
      system "./bootstrap"
    end
    curl "http://www.cl.cam.ac.uk/~mgk25/ucs/wcwidth.c",
         "-o", "./src/wcwidth.c" 
    system "echo", "#{prefix}"
    system "./configure", "--prefix=#{prefix}",
                          "--without-gmp"
    system "make"
    system "mkdir", "-p", "#{prefix}/bin"
    system "cp", "./src/ls", "#{prefix}/bin/ls"
  end

  test do
    (testpath/"test").write("test")
    (testpath/"test.sha1").write("a94a8fe5ccb19ba61c4c0873d391e987982fbbd3 test")
    system "#{bin}/gsha1sum", "-c", "test.sha1"
  end
end

__END__
diff --git a/Makefile.in b/Makefile.in
index 140a428..bae3163 100644
--- a/Makefile.in
+++ b/Makefile.in
@@ -2566,7 +2566,7 @@ pkglibexecdir = @pkglibexecdir@
 # Use 'ginstall' in the definition of PROGRAMS and in dependencies to avoid
 # confusion with the 'install' target.  The install rule transforms 'ginstall'
 # to install before applying any user-specified name transformations.
-transform = s/ginstall/install/; $(program_transform_name)
+transform = s/ginstall/install/;/libstdbuf/!$(program_transform_name)
 ACLOCAL = @ACLOCAL@
 ALLOCA = @ALLOCA@
 ALLOCA_H = @ALLOCA_H@
diff --git a/src/ls.c b/src/ls.c
index cd5996e..c9a70f2 100644
--- a/src/ls.c
+++ b/src/ls.c
@@ -110,6 +110,8 @@
 #include "mbsalign.h"
 #include "dircolors.h"
 
+#include "wcwidth.c"
+
 /* Include <sys/capability.h> last to avoid a clash of <sys/types.h>
    include guards with some premature versions of libcap.
    For more details, see <http://bugzilla.redhat.com/483548>.  */
@@ -4133,7 +4135,7 @@ quote_name (FILE *out, const char *name, struct quoting_options const *options,
                           /* A null wide character was encountered.  */
                           bytes = 1;
 
-                        w = wcwidth (wc);
+                        w = mk_wcwidth (wc);
                         if (w >= 0)
                           {
                             /* A printable multibyte character.
