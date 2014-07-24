package { "apache2":
  ensure => installed,
}

service { "apache2":
  enable => true,
  ensure => running,
  require => Package["apache2"],
}

package { "php5":
  ensure => installed,
  require => Package["apache2"],
  notify => Service["apache2"],
}

package { ['php5-mysql', 'php5-gd', 'php5-curl']:
  ensure => installed,
  require => Package["php5"],
  notify => Service["apache2"],
}

package { "wget":
  ensure => installed,
}

exec { "has-opencart.deb":
  command => "/usr/bin/wget http://j.mp/opencart-deb -O /tmp/opencart.deb",
  creates => "/tmp/opencart.deb",
  require => Package["wget"],
}

package { "opencart":
  ensure => latest,
  provider => dpkg,
  source => "/tmp/opencart.deb",
  require => [ Exec ["has-opencart.deb"], Package['php5-mysql', 'php5-gd', 'php5-curl'] ],
}

file { "/etc/apache2/sites-enabled/000-default":
  ensure => absent,
  require => Package["apache2"],
  notify => Service["apache2"]
}

file { "/etc/apache2/sites-enabled/opencart":
  ensure => link,
  target => "/etc/apache2/sites-available/opencart",
  require => Package["opencart"],
  notify => Service["apache2"],
}

$db_host = "db"
$db_user = "opencart"
$db_password = "openpass"
$db_database = "opencart"

file { "/var/opencart/config.php":
content => template("/vagrant/config.php"),
owner => www-data,
group => www-data,
mode => 440,
require => Package["opencart"],
}
