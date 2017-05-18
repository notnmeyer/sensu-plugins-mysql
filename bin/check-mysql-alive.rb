#!/usr/bin/env ruby
#
# MySQL Alive Plugin
# ===
#
# This plugin attempts to login to mysql with provided credentials.
#
# Copyright 2011 Joe Crim <josephcrim@gmail.com>
# Updated by Lewis Preson 2012 to accept a database parameter
# Updated by Oluwaseun Obajobi 2014 to accept ini argument
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# USING INI ARGUMENT
# This was implemented to load mysql credentials without parsing the username/password.
# The ini file should be readable by the sensu user/group.
# Ref: http://eric.lubow.org/2009/ruby/parsing-ini-files-with-ruby/
#
#   EXAMPLE
#     mysql-alive.rb -h db01 --ini '/etc/sensu/my.cnf'
#
#   MY.CNF INI FORMAT
#   [client]
#   user=sensu
#   password="abcd1234"
#

require 'sensu-plugin/check/cli'
require 'mysql2'
require 'inifile'

class CheckMySQL < Sensu::Plugin::Check::CLI
  option :user,
         description: 'MySQL User',
         short: '-u USER',
         long: '--user USER'

  option :password,
         description: 'MySQL Password',
         short: '-p PASS',
         long: '--password PASS'

  option :ini,
         description: 'My.cnf ini file',
         short: '-i',
         long: '--ini VALUE'

  option :hostname,
         description: 'Hostname to login to',
         short: '-h HOST',
         long: '--hostname HOST'

  option :database,
         description: 'Database schema to connect to',
         short: '-d DATABASE',
         long: '--database DATABASE',
         default: 'test'

  option :port,
         description: 'Port to connect to',
         short: '-P PORT',
         long: '--port PORT',
         default: '3306'

  option :socket,
         description: 'Socket to use',
         short: '-s SOCKET',
         long: '--socket SOCKET'

  def run
    if config[:ini]
      ini = IniFile.load(config[:ini])
      section = ini['client']
      db_user = section['user']
      db_pass = section['password']
    else
      db_user = config[:user]
      db_pass = config[:password]
    end

    begin
      db = Mysql2::Client.new(
        host: config[:hostname],
        username: db_user,
        password: db_pass,
        database: config[:database],
        port: config[:port].to_i,
        socket: config[:socket]
      )
      info = db.query('select version()').first.values.first
      ok "Server version: #{info}"
    rescue Mysql2::Error => e
      critical "Error message: #{e.error}"
    ensure
      db.close if db
    end
  end
end
