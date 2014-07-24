define appdb ($database, $username, $password) {

  exec { "create-$title":
    unless => "mysqlshow -uroot $database",
    command => "mysqladmin -uroot create $database",
    path => "/usr/bin",
    require => Class["mysql"],
  }

  exec { "grant-$title":
    unless => "mysqlshow -u$username -p$password $database ",
    command => "mysql -u root -e \"grant all on $database.* to '$username'@'%' identified by '$password'\"",
    path => "/usr/bin",
    require => Exec["create-$title"],
  }

}
