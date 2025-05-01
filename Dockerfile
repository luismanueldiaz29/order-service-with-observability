# Etapa 1: Build con Gradle
ARG BUILDER_IMAGE=gradle:7.4.2-jdk17-alpine
ARG PRODUCTION_IMAGE=amazoncorretto:17-alpine3.15

FROM ${BUILDER_IMAGE} as builder

WORKDIR /home/app

# Copia solo los archivos necesarios para resolver dependencias primero
COPY build.gradle settings.gradle gradlew ./
COPY gradle /home/app/gradle
RUN ./gradlew build -x test --no-daemon || true

# Copia el resto del proyecto y compila
COPY . .
RUN ./gradlew clean build -x test --no-daemon

# Etapa 2: Imagen liviana para producción
FROM ${PRODUCTION_IMAGE} as production

ENV APP_PORT=8084

# Copia el jar construido y el agente de OpenTelemetry
COPY --from=builder /home/app/build/libs/*-SNAPSHOT.jar /home/app/application.jar
COPY --from=builder /home/app/build/agent/opentelemetry-javaagent.jar /opentelemetry-javaagent.jar

EXPOSE ${APP_PORT}

ENTRYPOINT ["java", "-javaagent:/opentelemetry-javaagent.jar", "-jar", "/home/app/application.jar"]
