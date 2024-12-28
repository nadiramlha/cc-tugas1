terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}


provider "local" {}
provider "null" {}

variable "web_root" {
  default = "/var/www/html"
}

variable "git_repo" {
  default = "https://github.com/rm77/web-sample-6.git"
}

resource "null_resource" "update_apt" {
  provisioner "local-exec" {
    command = "sudo apt-get update -y"
  }
}

resource "null_resource" "install_lamp"{
  provisioner "local-exec" {
    command = <<EOT
      sudo apt-get install -y apache2 mysql-server php lipapache2-mod-php php-mysql phpmyadmin git unzip
    EOT
  }
}

resource "null_resource" "ensure_services" {
  provisioner "local-exec" {
    command = <<EOT
      sudo systemctl start apache2
      sudo systemctl enable apache2
      sudo systemctl start mysql
      sudo systemctl enable mysql
    EOT
  }
}

resource "local_file" "phpmyadmin_config" {
  content = <<EOT
<?php
$cfg['blowfish_secret'] = 'key';
$i = 0;
$i++;
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = 'localhost';
$cfg['Servers'][$i]['AllowNoPassword'] = false;
?>
EOT
  filename = "/tmp/config.inc.php"
}

resource "null_resource" "copy_phpmyadmin_config" {
  provisioner "local-exec" {
    command = "sudo cp /tmp/config.inc.php /etc/phpmyadmin/config.inc.php"
  }
}

resource "null_resource" "remove_web_root" {
  provisioner "local-exec" {
    command = <<EOT
      sudo git clone ${var.git_repo} ${var.web_root} &&
      sudo chown -R www-data:www-data ${var.web_root} &&
      sudo chown -R 0755 ${var.web_root}
    EOT
  }
}

resource "null_resource" "clone_repo" {
  provisioner "local-exec" {
    command = <<EOT
      sudo rm -f /etc/apache2/conf-available/phpmyadmin.conf &&
      sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
    EOT
  }
}

resource "null_resource" "create_symlink_phpmyadmin" {
  provisioner "local-exec" {
    command = <<EOT
      sudo rm -f /etc/apache2/conf-available/phpmyadmin.conf &&
      sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
    EOT
  }
}

resource "null_resource" "set_document_root" {
  provisioner "local-exec" {
    command = <<EOT
      sudo sed -i 's|DocumentRoot .*|DocumentRoot ${var.web_root}|' /etc/apache2/sites-available
    EOT
  }
}

resource "null_resource" "enable_phpmyadmin" {
  provisioner "local-exec" {
    command = <<EOT
      sudo a2enconf phpmyadmin &&
      sudo systemctl reload apache2
    EOT
  }
}
