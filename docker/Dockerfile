FROM eclipse-temurin:21-jre-jammy

RUN groupadd -r spring && useradd -r -g spring spring

# Path is now relative to the project root
COPY --chown=spring:spring docker/profiler-artifacts/async-profiler /opt/async-profiler

USER spring:spring
WORKDIR /app
RUN mkdir /app/profiles

# Path is now relative to the project root
COPY --chown=spring:spring spring-boot-app/target/synthetic-load-api-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]