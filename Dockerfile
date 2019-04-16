FROM ocrd/core:latest
ENV VERSION="Tue Apr 16 13:43:59 UTC 2019"
ENV GITURL="https://github.com/cisocrgroup"
ENV DATA="/apps/ocrd-cis-post-correction"

# deps
COPY data/docker/deps.txt ${DATA}/deps.txt
RUN apt-get update && \
	apt-get -y install --no-install-recommends $(cat ${DATA}/deps.txt)

# copy cis-ocrd scripts and configuration
COPY bashlib/ocrd-cis-lib.sh \
	bashlib/ocrd-cis-docker-train.sh\
	bashlib/ocrd-cis-post-correct.sh\
	/apps/
COPY data/docker/ocrd-cis-post-correction.json\
	data/docker/ocrd-cis-ocropy-fraktur1.json\
	data/docker/ocrd-cis-ocropy-fraktur2.json\
	${DATA}/config/
RUN sed -i -e "s#\${DATA}#${DATA}#g" ${DATA}/config/*.json

# install the profiler
RUN	git clone ${GITURL}/Profiler --branch devel --single-branch /tmp/profiler &&\
	cd /tmp/profiler &&\
	mkdir build &&\
	cd build &&\
	cmake -DCMAKE_BUILD_TYPE=release .. &&\
	make compileFBDic trainFrequencyList profiler &&\
	cp bin/compileFBDic bin/trainFrequencyList bin/profiler /apps/ &&\
	cd / &&\
    rm -rf /tmp/profiler

# install the profiler's language backend
RUN	git clone ${GITURL}/Resources --branch master --single-branch /tmp/resources &&\
	cd /tmp/resources/lexica &&\
	make FBDIC=/apps/compileFBDic TRAIN=/apps/trainFrequencyList &&\
	mkdir -p /${DATA}/languages &&\
	cp -r german latin greek german.ini latin.ini greek.ini /${DATA}/languages &&\
	cd / &&\
	rm -rf /tmp/resources

# install cis-ocrd-py
RUN git clone ${GITURL}/cis-ocrd-py --branch dev --single-branch /tmp/cis-ocrd-py &&\
	cd /tmp/cis-ocrd-py &&\
	pip install --upgrade pip &&\
	pip install 'pillow<6.0.0' . &&\
	cd / &&\
	rm -rf /tmp/cis-ocrd-py

# install cis-ocrd-py
RUN git clone ${GITURL}/ocrd-postcorrection --branch dev --single-branch /tmp/ocrd-postcorrection &&\
	cd /tmp/ocrd-postcorrection &&\
	mvn -DskipTests package &&\
	cp target/ocrd-0.1-cli.jar /apps/ocrd-cis.jar &&\
	cd / &&\
	rm -rf /tmp/ocrd-postcorrection

# download ocr models and pre-trainded post-correction model
RUN mkdir ${DATA}/models &&\
	cd ${DATA}/models &&\
	wget cis.lmu.de/~finkf/model.zip &&\
	wget cis.lmu.de/~finkf/fraktur1-00085000.pyrnn.gz &&\
	wget cis.lmu.de/~finkf/fraktur2-00062000.pyrnn.gz

# TODOS:
# - implement/adjust training script
# - implement helper post-correction script
VOLUME ["/data"]
ENTRYPOINT ["/bin/sh", "-c"]
