FROM ubuntu:16.04

ARG DOWNLOAD_LINK=http://registrationcenter-download.intel.com/akdlm/irc_nas/15693/l_openvino_toolkit_p_2019.2.242.tgz
ARG INSTALL_DIR=/opt/intel/openvino
ARG TEMP_DIR=/tmp/openvino_installer

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    cpio \
    sudo \
    lsb-release \
    libgtk-3-dev && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p $TEMP_DIR && cd $TEMP_DIR && \
    wget -c $DOWNLOAD_LINK && \
    tar xf l_openvino_toolkit*.tgz && \
    cd l_openvino_toolkit* && \
    sed -i 's/decline/accept/g' silent.cfg && \
    ./install.sh -s silent.cfg && \
    rm -rf $TEMP_DIR

RUN $INSTALL_DIR/install_dependencies/install_openvino_dependencies.sh

RUN /opt/intel/openvino/deployment_tools/inference_engine/samples/build_samples.sh

RUN apt-get update && apt-get install python3-pip -y && \
    pip3 install pyyaml requests && \
    cd /opt/intel/openvino/deployment_tools/tools/model_downloader && \
    python3 downloader.py --name alexnet

RUN cd /opt/intel/openvino/deployment_tools/model_optimizer && \
    ./install_prerequisites/install_prerequisites.sh && \
    python3 mo.py --input_model ../tools/model_downloader/classification/alexnet/caffe/alexnet.caffemodel

RUN cd ~ && \
    wget "https://images.pexels.com/photos/87446/animal-ape-chimp-chimpanzee-87446.jpeg?auto=compress&cs=tinysrgb&dpr=3&h=750&w=1260" -O ~/chimp.jpg

RUN echo "source /opt/intel/openvino/bin/setupvars.sh" >> ~/.bashrc

RUN cd /opt/intel/openvino/install_dependencies/; \
    ./install_NEO_OCL_driver.sh

RUN usermod -aG video root

COPY test_gpu.sh /root/inference_engine_samples_build/intel64/Release/

WORKDIR /root/inference_engine_samples_build/intel64/Release/

CMD bash test_gpu.sh
