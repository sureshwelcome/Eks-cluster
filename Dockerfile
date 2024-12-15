FROM openjdk:11 AS BUILD_IMAGE
RUN apt update && apt install -y wget gnupg
RUN wget -q -O - https://www.apache.org/dist/maven/KEYS | apt-key add -
RUN echo "deb http://www.apache.org/dist/maven/binaries/ /" > /etc/apt/sources.list.d/maven.list
RUN apt update && apt install -y maven
RUN git clone https://github.com/devopshydclub/vprofile-project.git
RUN cd vprofile-project && git checkout docker && mvn install

FROM tomcat:9-jre11

RUN rm -rf /usr/local/tomcat/webapps/*

COPY --from=BUILD_IMAGE vprofile-project/target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
