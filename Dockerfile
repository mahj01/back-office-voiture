# ========================================
# Dockerfile pour Spring MVC (WAR) sur Tomcat
# ========================================

# Etape 1: Build avec Maven
FROM maven:3.9.4-eclipse-temurin-17 AS build
WORKDIR /workspace

# Copier les sources du back-office (projet Maven dans ./backoffice)
COPY backoffice/pom.xml ./
COPY backoffice/src ./src

# Dépendance locale requise par le projet
# Placez url-echo-servlet-1.0.jar dans backoffice/
COPY backoffice/url-echo-servlet-1.0.jar ./url-echo-servlet-1.0.jar

RUN mvn -q org.apache.maven.plugins:maven-install-plugin:3.1.0:install-file \
	-Dfile=/workspace/url-echo-servlet-1.0.jar \
	-DgroupId=com.itu \
	-DartifactId=url-echo-servlet \
	-Dversion=1.0 \
	-Dpackaging=jar \
 && mvn -B -DskipTests clean package

# Etape 2: Déploiement sur Tomcat
FROM tomcat:10.1-jdk17-temurin

# Supprimer les apps par défaut de Tomcat
RUN rm -rf /usr/local/tomcat/webapps/*

# Copier le WAR (renommé ROOT.war pour qu'il soit accessible à la racine /)
COPY --from=build /workspace/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]