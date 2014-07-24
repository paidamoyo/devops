class mysql {

  package { "mysql-server":
    ensure => installed,
  }

  file {"/etc/mysql/conf.d/allow_external.cnf":
    owner => mysql,
    group => mysql,
    mode => 0644,
    content => template("database/etc/msql/conf.d/allow_external.cnf"),
    notify => Service["mysql"],
    require => Package["mysql-server"],
  }

  service { "mysql":
    enable => true,
    ensure => running,
    hasrestart => true,
    hasstatus => true,
    require => Package["mysql-server"],
  }

}
