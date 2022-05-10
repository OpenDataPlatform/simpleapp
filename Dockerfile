ARG img_base

FROM ${img_base}

COPY py/create_table.py /opt/
ARG sapp_version
COPY java/build/libs/simpleapp-${sapp_version}-uber.jar /opt/

