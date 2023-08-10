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
  filename = "${abspath(path.module)}/out/BuildTools.jar"
  content_base64 = data.http-bin.build-tools-jar-content.response_body
}

# CraftBukkit
resource "null_resource" "craftbukkit-jar-compilation" {
  provisioner "local-exec" {
    working_dir = "${abspath(path.module)}/out"
    command = join(";\n", [
      "mkdir BuildTools",
      "cd BuildTools",
      "/opt/homebrew/opt/openjdk/bin/java -jar ${local_sensitive_file.build-tools-jar.filename} --rev 1.20.1 --compile craftbukkit"
    ])
  }

  provisioner "local-exec" {
    when = destroy
    working_dir = "${abspath(path.module)}/out"
    command = "rm -rf BuildTools"
  }
}

resource "local_file" "craftbukkit-jar" {
  filename = "${abspath(path.module)}/out/BuildTools/craftbukkit-1.20.1.jar"
  source = "${abspath(path.module)}/out/BuildTools/craftbukkit-1.20.1.jar"
  depends_on = [null_resource.craftbukkit-jar-compilation]
}

# server.properties
resource "local_file" "server-properties" {
  filename = "${abspath(path.module)}/out/Server/server.properties"
  content = join("\n", [
    "motd=A \\u00A75Terraform\\u00A7r-Provisioned Minecraft Server!",
    "gamemode=creative",
    "level-seed=t3rr4f0rm-w00t!"
  ])
}

# EULA
resource "local_file" "minecraft-eula" {
  filename = "${abspath(path.module)}/out/Server/eula.txt"
  content = "eula=true"
}

# Plugins (Dynmap)

# Plugin configuration

# Server start
resource "null_resource" "server" {
  depends_on = [
    local_file.minecraft-eula,
    local_file.server-properties
  ]

  provisioner "local-exec" {
    working_dir = "${abspath(path.module)}/out/Server"
    command = "tmux new-session -d -s mc-server '/opt/homebrew/opt/openjdk/bin/java -jar \"${local_file.craftbukkit-jar.filename}\" --nogui; tmux wait-for -S mc-server-closed'"
  }

  provisioner "local-exec" {
    when = destroy
    working_dir = "${abspath(path.module)}/out"
    command = "tmux kill-session -t mc-server\\; wait-for mc-server-closed || true"
  }
}
