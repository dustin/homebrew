require 'formula'

class Mplayer < Formula
  homepage 'http://www.mplayerhq.hu/'
  url 'http://www.mplayerhq.hu/MPlayer/releases/MPlayer-1.1.tar.xz'
  sha1 '913a4bbeab7cbb515c2f43ad39bc83071b2efd75'

  head 'svn://svn.mplayerhq.hu/mplayer/trunk', :using => StrictSubversionDownloadStrategy

  option 'with-x', 'Build with X11 support'

  depends_on 'pkg-config' => :build
  depends_on 'yasm' => :build
  depends_on 'xz' => :build
  depends_on :x11 if build.include? 'with-x'

  fails_with :clang do
    build 211
    cause 'Inline asm errors during compile on 32bit Snow Leopard.'
  end unless MacOS.prefer_64_bit?

  def patches
    # When building SVN, configure prompts the user to pull FFmpeg from git.
    # Don't do that.
    DATA if build.head?
  end

  def install
    # (A) Do not use pipes, per bug report and MacPorts
    # * https://github.com/mxcl/homebrew/issues/622
    # * http://trac.macports.org/browser/trunk/dports/multimedia/mplayer-devel/Portfile
    # (B) Any kind of optimisation breaks the build
    # (C) It turns out that ENV.O1 fixes link errors with llvm.
    ENV['CFLAGS'] = ''
    ENV['CXXFLAGS'] = ''
    ENV.O1 if ENV.compiler == :llvm

    # we disable cdparanoia because homebrew's version is hacked to work on OS X
    # and mplayer doesn't expect the hacks we apply. So it chokes.
    # Specify our compiler to stop ffmpeg from defaulting to gcc.
    # Disable openjpeg because it defines int main(), which hides mplayer's main().
    # This issue was reported upstream against openjpeg 1.5.0:
    # http://code.google.com/p/openjpeg/issues/detail?id=152
    args = %W[
      --prefix=#{prefix}
      --cc=#{ENV.cc}
      --host-cc=#{ENV.cc}
      --disable-cdparanoia
      --disable-libopenjpeg
    ]

    args << "--disable-x11" unless build.include? 'with-x'

    system "./configure", *args
    system "make"
    system "make install"
  end
end

__END__
diff --git a/configure b/configure
index bbfcd51..5734024 100755
--- a/configure
+++ b/configure
@@ -48,8 +48,6 @@ if test -e ffmpeg/mp_auto_pull ; then
 fi
 
 if ! test -e ffmpeg ; then
-    echo "No FFmpeg checkout, press enter to download one with git or CTRL+C to abort"
-    read tmp
     if ! git clone --depth 1 git://git.videolan.org/ffmpeg.git ffmpeg ; then
         rm -rf ffmpeg
         echo "Failed to get a FFmpeg checkout"
