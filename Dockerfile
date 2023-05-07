FROM intel/oneapi-basekit:2023.1.0-devel-ubuntu22.04

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y \
	software-properties-common \
	build-essential \
	gcc \
	g++ \
	gfortran \
	git \
	patch \
	wget \
	pkg-config \
	liblapack-dev \
	libmetis-dev \
	gnuplot \
	vim \
	swig \
	clang \
	less \
	&& rm -rf /var/lib/apt/lists/*

# Install Rust
ARG RUST_VERSION
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${RUST_VERSION}
ENV PATH $PATH:/root/.cargo/bin

# Ipoptのインストール
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/usr/local/lib
ENV PKG_CONFIG_PATH $PKG_CONFIG_PATH:/usr/local/lib/pkgconfig
ARG LIBDIR_TMP
RUN mkdir -p ${LIBDIR_TMP} && cd ${LIBDIR_TMP} \
	&& git clone https://github.com/coin-or/Ipopt.git && cd Ipopt \
	&& mkdir third-lib && cd third-lib \
	&& git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git && cd ThirdParty-Mumps \
	&& ./get.Mumps && ./configure --with-lapack="-L${MKLROOT}/lib/intel64 -Wl,--no-as-needed -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lm" && /usr/bin/make && /usr/bin/make install \
	&& cd ${LIBDIR_TMP}/Ipopt && mkdir build && cd build \
	&& ../configure --with-lapack="-L${MKLROOT}/lib/intel64 -Wl,--no-as-neede -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lm" --disable-java --without-hsl --without-asl \
	&& /usr/bin/make && /usr/bin/make test && /usr/bin/make install
RUN /usr/bin/ln -s /usr/local/include/coin-or /usr/local/include/coin

# ipopt-rsのテスト
# RUN cd ${LIBDIR_TMP} && git clone https://github.com/elrnv/ipopt-rs.git \
RUN cd ${LIBDIR_TMP} && git clone https://github.com/rmarui/ipopt-rs.git \
	&& cd ./ipopt-rs/ipopt-sys && cargo build && cargo test \
	&& cd .. && cargo build && cargo test
