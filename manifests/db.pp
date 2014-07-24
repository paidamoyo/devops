import "database"
include mysql

appdb {"opencart-db":
  database => "opencart",
  username => "opencart",
  password => "openpass",
}


file { "/root/opencart.sql":
  content => template("/vagrant/opencart.sql"),
}

exec { "load-opencart-schema":
  command => "/usr/bin/mysql -uopencart -popenpass opencart < /root/opencart.sql",
  refreshonly => true,
  subscribe => File["/root/opencart.sql"],
  require => [Appdb ["opencart-db"], File["/root/opencart.sql"] ],
}

