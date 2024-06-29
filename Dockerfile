ARG FROM_TAG="22.04"
FROM ubuntu:${FROM_TAG}

ARG DEBIAN_FRONTEND=noninteractive

# Install Qt5
RUN apt-get update && apt-get install -y \
    qtbase5-private-dev qtscript5-dev \
    qml-module-qt-labs-folderlistmodel qml-module-qtquick-extras \
    qml-module-qtquick-controls2 qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libqt5quickcontrols2-5 qtquickcontrols2-5-dev \
    qtcreator qtcreator-doc libqt5serialport5-dev qml-module-qt3d qt3d5-dev \
    qtdeclarative5-dev qtconnectivity5-dev qtmultimedia5-dev qtpositioning5-dev \
    libqt5gamepad5-dev qml-module-qt-labs-settings qml-module-qt-labs-platform libqt5svg5-dev

# Install other dependencies
RUN apt-get update && \
    apt-get install -y wget make bzip2 python3 python-is-python3 git build-essential && \
    apt-get clean

# Install other dependencies
RUN apt-get update && \
    apt-get install -y autoconf automake autopoint bash bison bzip2 flex gettext git g++ gperf intltool libffi-dev libgdk-pixbuf2.0-dev libtool libltdl-dev libssl-dev libxml-parser-perl make openssl p7zip-full patch perl pkg-config python3 ruby scons sed unzip wget xz-utils g++-multilib libc6-dev-i386 libtool-bin lzip python3-mako python3-packaging && \
    apt-get clean \

RUN ln -s /usr/bin/python3 /usr/bin/python

# Install ARM toolchain
ARG ARM_SDK_FILE=gcc-arm-none-eabi-7-2018-q2-update-linux.tar.bz2 
RUN wget --no-check-certificate -N -P /tmp https://developer.arm.com/-/media/Files/downloads/gnu-rm/7-2018q2/${ARM_SDK_FILE} && \
    tar -C /opt -xjf /tmp/${ARM_SDK_FILE}  && \
    rm /tmp/${ARM_SDK_FILE}

# Define standard paths used by other scripts
ARG ROOT_PATH=/workspace/vedderb
ENV VESC_FW_PATH=${ROOT_PATH}/bldc
ENV VESC_TOOL_PATH=${ROOT_PATH}/vesc_tool
ENV VESC_PKG_PATH=${ROOT_PATH}/vesc_pkg

# Configure git to ignore Windows line endings
RUN git config --global core.autocrlf false

RUN git clone https://github.com/mxe/mxe.git /opt/mxe2

RUN cd /opt/mxe2 && \
    make -j16 qtbase && \
    make -j16 qtserialport && \
    make -j16 qtconnectivity && \
    make -j16 qtquickcontrols && \
    make -j16 qtquickcontrols2 && \
    make -j16 qtserialbus && \
    make -j16 qtlocation && \
    make -j16 qtgamepad && \
    make -j16 qtgraphicaleffects

# Clone VESC repos- DOESN'T WORK
RUN mkdir -p /vedderb && \
    git clone https://github.com/vedderb/bldc.git ${VESC_FW_PATH} && \
    git clone https://github.com/vedderb/vesc_tool.git ${VESC_TOOL_PATH} && \
    git clone https://github.com/vedderb/vesc_pkg.git ${VESC_PKG_PATH}

# Apply patches
RUN echo "Fixing harcoded FWPATH in vesc_tool/build_cp_fw" && \
    sed -i 's|FWPATH="../../ARM/STM_Eclipse/BLDC_4_ChibiOS/"|FWPATH="'"${VESC_FW_PATH}"'"|' ${VESC_TOOL_PATH}/build_cp_fw

# Add ARM toolchain to PATH
ENV PATH="${PATH}:/opt/gcc-arm-none-eabi-7-2018-q2-update/bin"

# Add future directory containing vesc_tool to PATH
ENV PATH="${PATH}:/workspace/build"
