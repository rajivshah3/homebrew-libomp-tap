class LibompAT1110 < Formula
  desc "LLVM's OpenMP runtime library"
  homepage "https://openmp.llvm.org/"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-11.1.0/openmp-11.1.0.src.tar.xz"
  sha256 "d187483b75b39acb3ff8ea1b7d98524d95322e3cb148842957e9b0fbb866052e"
  license "MIT"

  livecheck do
    url "https://llvm.org/"
    regex(/LLVM (\d+\.\d+\.\d+)/i)
  end

  bottle do
    root_url "https://github.com/rajivshah3/homebrew-libomp-tap/releases/download/libomp@11.1.0-11.1.0"
    sha256 cellar: :any,                 catalina:     "4d35c910f3da2310958de8cd4931f1f2229c597473ce213b4a1d77224979ac9e"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "c4e846ac831d4b2fc244d9cbb1fe24f02e9fd1e933e4ae385851becb99817b50"
  end

  depends_on "cmake" => :build

  # Upstream patch for ARM, accepted, remove in next version
  # https://reviews.llvm.org/D91002
  # https://bugs.llvm.org/show_bug.cgi?id=47609
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/7e2ee1d7/libomp/arm.patch"
    sha256 "6de9071e41a166b74d29fe527211831d2f8e9cb031ad17929dece044f2edd801"
  end

  def install
    # Disable LIBOMP_INSTALL_ALIASES, otherwise the library is installed as
    # libgomp alias which can conflict with GCC's libgomp.
    system "cmake", ".", *std_cmake_args, "-DLIBOMP_INSTALL_ALIASES=OFF"
    system "make", "install"
    system "cmake", ".", "-DLIBOMP_ENABLE_SHARED=OFF", *std_cmake_args,
                         "-DLIBOMP_INSTALL_ALIASES=OFF"
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <omp.h>
      #include <array>
      int main (int argc, char** argv) {
        std::array<size_t,2> arr = {0,0};
        #pragma omp parallel num_threads(2)
        {
            size_t tid = omp_get_thread_num();
            arr.at(tid) = tid + 1;
        }
        if(arr.at(0) == 1 && arr.at(1) == 2)
            return 0;
        else
            return 1;
      }
    EOS
    system ENV.cxx, "-Werror", "-Xpreprocessor", "-fopenmp", "test.cpp",
                    "-L#{lib}", "-lomp", "-o", "test"
    system "./test"
  end
end
