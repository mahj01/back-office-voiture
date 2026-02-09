# ========================================
# Dockerfile pour Spring MVC (WAR) sur Tomcat
# ========================================

# Etape 1: Build avec Maven
FROM maven:3.9.4-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY ./backoffice/pom.xml ./
COPY ./backoffice/src ./src
RUN mvn -B -DskipTests clean package

# Etape 2: Déploiement sur Tomcat
FROM tomcat:10.1-jdk17-temurin

# Supprimer les apps par défaut de Tomcat
RUN rm -rf /usr/local/tomcat/webapps/*

# Copier le WAR (renommé ROOT.war pour qu'il soit accessible à la racine /)
COPY --from=build /workspace/target/*.war /usr/local/tomcat/webapps/ROOT.war

# Variables d'environnement pour la configuration
# SERVICE_URL: URL du back-office (à définir dans Railway)
ENV SERVICE_URL=http://localhost:8080/back-office-voiture

EXPOSE 8080

CMD ["catalina.sh", "run"]