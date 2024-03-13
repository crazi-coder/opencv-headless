# FROM jupyter/pyspark-notebook:ubuntu-22.04
FROM python:3.12-alpine3.19  AS build-stage 
RUN apk update &&  apk update && apk add --no-cache build-base cmake git pkgconfig wget \
    libjpeg-turbo-dev libpng-dev tiff-dev \
    linux-headers musl-dev openblas-dev \
    python3-dev py3-pip

RUN pip install numpy==1.26.4
RUN git clone https://github.com/opencv/opencv.git
RUN git clone https://github.com/opencv/opencv_contrib.git
RUN cd opencv_contrib && git checkout 4.9.0  && \
    cd ../opencv && git checkout 4.9.0
RUN mkdir build && cd build  && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=/usr/local \
      -D BUILD_opencv_python2=OFF \
      -D BUILD_opencv_python3=ON \
      -D PYTHON3_EXECUTABLE=$(which python3) \
      -D PYTHON3_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
      -D PYTHON3_LIBRARIES=$(python3 -c "import distutils.sysconfig as sysconfig; print(sysconfig.get_config_var('LIBDIR'))") \
      -D PYTHON3_NUMPY_INCLUDE_DIRS=$(python3 -c "import numpy; print(numpy.get_include())") \
      -D PYTHON3_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
      -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
      -D BUILD_EXAMPLES=OFF \
      -D BUILD_DOCS=OFF \
      -D BUILD_TESTS=OFF \
      -D BUILD_PERF_TESTS=OFF \
      -D WITH_FFMPEG=NO \
      -D WITH_IPP=NO \
      -D WITH_OPENEXR=NO \
      -D WITH_QT=OFF \
      -D WITH_GTK=OFF \
      -D WITH_OPENGL=OFF \
      -D WITH_VTK=OFF \
      ../opencv && \
    make -j$(nproc) -s &&  \
    make install

# Define the final stage
FROM python:3.12-alpine3.19 

RUN apk update cache && apk add --no-cache --upgrade expat # CEV 2.5.0-r2 FIX

# Copy OpenCV from build-stage to the final image
COPY --from=build-stage /usr/local /usr/local
# Install runtime dependencies
RUN apk update && apk add --no-cache libstdc++ libpng libjpeg-turbo tiff openblas libc-dev && \
    ln -s /usr/include/locale.h /usr/include/xlocale.h

