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
    apt-get install -y wget make bzip2 python3 git build-essential && \
    apt-get clean

# Install other dependencies
RUN apt-get update && \
    apt-get install -y autoconf automake autopoint bash bison bzip2 flex gettext git g++ gperf intltool libffi-dev libgdk-pixbuf2.0-dev libtool libltdl-dev libssl-dev libxml-parser-perl make openssl p7zip-full patch perl pkg-config python3 ruby scons sed unzip wget xz-utils g++-multilib libc6-dev-i386 libtool-bin lzip python3-mako python3-packaging && \
    apt-get clean


# Install ARM toolchain
RUN apt-get update && apt-get install -y gcc-arm-none-eabi && apt clean

# Define standard paths used by other scripts
ARG ROOT_PATH=/workspace/vedderb
ENV VESC_FW_PATH=${ROOT_PATH}/bldc
ENV VESC_TOOL_PATH=${ROOT_PATH}/vesc_tool
ENV VESC_PKG_PATH=${ROOT_PATH}/vesc_pkg

# Configure git to ignore Windows line endings
RUN git config --global core.autocrlf false

# Clone VESC repos- DOESN'T WORK
RUN mkdir -p /vedderb && \
    git clone https://github.com/vedderb/bldc.git ${VESC_FW_PATH} && \
    git clone https://github.com/vedderb/vesc_tool.git ${VESC_TOOL_PATH} && \
    git clone https://github.com/vedderb/vesc_pkg.git ${VESC_PKG_PATH}

RUN mkdir ${VESC_FW_PATH}/tools 
RUN ln -s /usr ${VESC_FW_PATH}/tools/gcc-arm-none-eabi-7-2018-q2-update
# Apply patches
RUN echo "Fixing harcoded FWPATH in vesc_tool/build_cp_fw" && \
    sed -i 's|FWPATH="../../ARM/STM_Eclipse/BLDC_4_ChibiOS/"|FWPATH="'"${VESC_FW_PATH}"'"|' ${VESC_TOOL_PATH}/build_cp_fw

RUN cd ${VESC_FW_PATH} && make -j16 Little_FOCer_V3_1 && python3 package_firmware.py
RUN cp -r ${VESC_FW_PATH}/package/* ${VESC_TOOL_PATH}/res/firmwares/
RUN cd ${VESC_TOOL_PATH} && ./build_lin_original_only
RUN export file=$(find ${VESC_TOOL_PATH}/build/lin/vesc_tool* -type f | head -n 1) && echo "$file" && cd ${VESC_PKG_PATH} && VESC_TOOL=$file make -j16 float
