terraform {
  required_providers {
    http-bin = {
      source = "ndemeshchenko/http-bin"
      version = "1.0.1"
    }
  }
}

# Latest BuildTools
data "http-bin" "build-tools-jar-content" {
  url = "https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"
}

resource "local_sensitive_file" "build-tools-jar" {
  filename = "out/BuildTools/BuildTools.jar"
  content_base64 = data.http-bin.build-tools-jar-content.response_body
}

# Build CraftBukkit

# Java 17

# Server start (script?)

# server.properties

# EULA

# Plugins (Dynmap)

# Plugin configuration
