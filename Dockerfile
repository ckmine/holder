FROM ubuntu
RUN apt update 
RUN apt install wget tar curl sed -y
RUN wget https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz
RUN tar xvzf openjdk-17.0.2_linux-x64_bin.tar.gz
RUN mv jdk-17.0.2/ /opt/jdk-17/
ENV JAVA_HOME=/opt/jdk-17
ENV PATH=$PATH:$JAVA_HOME/bin
# CMD source ~/.bashrc
RUN mkdir /opt/tomcat/
RUN wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.76/bin/apache-tomcat-9.0.76.tar.gz
RUN tar xvzf apache-tomcat-9.0.76.tar.gz
RUN cp -rf apache-tomcat-9.0.76/* /opt/tomcat/
WORKDIR /opt/tomcat
RUN useradd tomcat
RUN chgrp -R tomcat /opt/tomcat
RUN chmod -R g=x+r /opt/tomcat
COPY epps-smartERP.war /opt/tomcat/webapps/
RUN sed -i '$i<role rolename="manager-gui"/><user username="tomcat" password="1234" roles="manager-gui"/><role rolename="admin-gui"/><user username="admin" password="1234" roles="admin-gui"/>' /opt/tomcat/conf/tomcat-users.xml
RUN sed -i '21,22d' /opt/tomcat/webapps/manager/META-INF/context.xml
RUN sed -i '21,22d' /opt/tomcat/webapps/host-manager/META-INF/context.xml
EXPOSE 8080
CMD /opt/tomcat/bin/catalina.sh run
