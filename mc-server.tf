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
  filename = "${abspath(path.module)}/out/BuildTools/BuildTools.jar"
  content_base64 = data.http-bin.build-tools-jar-content.response_body
}

# CraftBukkit
resource "null_resource" "craftbukkit-jar-compilation" {
  provisioner "local-exec" {
    working_dir = "${abspath(path.module)}/out/BuildTools"
    command = "/opt/homebrew/opt/openjdk/bin/java -jar ${local_sensitive_file.build-tools-jar.filename} --rev 1.20.1 --compile craftbukkit"
  }
}

resource "local_file" "craftbukkit-jar" {
  filename = "${abspath(path.module)}/out/craftbukkit-1.20.1.jar"
  source = "${abspath(path.module)}/out/BuildTools/craftbukkit-1.20.1.jar"
  depends_on = [null_resource.craftbukkit-jar-compilation]
}

# server.properties

# EULA
resource "local_file" "minecraft-eula" {
  filename = "${abspath(path.module)}/out/eula.txt"
  content = "eula=true"
}

# Plugins (Dynmap)

# Plugin configuration

# Server start
resource "null_resource" "server-start" {
  depends_on = [local_file.minecraft-eula]

  provisioner "local-exec" {
    working_dir = "${abspath(path.module)}/out"
    command = "/opt/homebrew/opt/openjdk/bin/java -jar ${local_file.craftbukkit-jar.filename}" # --nogui
  }
}
