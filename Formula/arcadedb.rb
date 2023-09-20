class Arcadedb < Formula
  desc "ArcadeDB Multi-Model Database, one DBMS that supports SQL, Cypher, Gremlin, HTTP/JSON, MongoDB and Redis"
  homepage "https://arcadedb.com/"
  url "https://github.com/ArcadeData/arcadedb/releases/download/23.7.1/arcadedb-23.7.1.tar.gz"
  sha256 "f014c0badc61f19237d12fd829fdbf6b4b45a7fb6f51181bd802d977cc7829b2"
  license "Apache-2.0"

  def install
    rm_f Dir["bin/*.bat"]
    chmod 0755, Dir["bin/*"]

    # remove empty directories, we'll create links to shared location
    rm_rf "databases"
    rm_rf "log"

    inreplace "bin/server.sh" do |s|
      s.gsub! 'ARCADEDB_PID=$ARCADEDB_HOME/bin/arcadedb.pid',
              "ARCADEDB_PID=#{var}/run/arcadedb/arcadedb.pid"
      s.gsub! '-Djava.util.logging.config.file=config/arcadedb-log.properties',
              "-Djava.util.logging.config.file=#{libexec}/config/arcadedb-log.properties"
    end

    if not pkgetc.exist?
      pkgetc.mkpath
      cp_r Dir["config/*"], pkgetc
    end
    rm_rf "config"

    libexec.install Dir["*"]

    (bin/"arcadedb-server").write <<~EOS
      #!/bin/bash
      cd "#{libexec}"
      JAVA_HOME="#{Formula["openjdk"].opt_prefix}" bin/server.sh "$@"
    EOS
    chmod 0755, bin/"arcadedb-server"

    (bin/"arcadedb-console").write <<~EOS
      #!/bin/bash
      cd "#{libexec}"
      JAVA_HOME="#{Formula["openjdk"].opt_prefix}" bin/console.sh "$@"
    EOS
    chmod 0755, bin/"arcadedb-console"
  end

  def post_install
    # use /usr/local/var/run/arcadedb as the default dir to store pid file
    (var/"run/arcadedb").mkpath
    
    # use /usr/local/var/db/arcadedb as the default databases dir
    # and link databases to it
    (var/"db/arcadedb").mkpath
    libexec.install_symlink var/"db/arcadedb" => "databases"

    # use /usr/local/var/log/arcadedb as the default log dir
    # and link log directory to it
    (var/"log/arcadedb").mkpath
    libexec.install_symlink var/"log/arcadedb" => "log"
    
    # use /usr/local/etc/arcadedb as the default config dir
    # and link config directory to it
    pkgetc.mkpath
    libexec.install_symlink pkgetc => "config"

    touch "#{var}/log/arcadedb/arcadedb.err"
    touch "#{var}/log/arcadedb/arcadedb.log"
  end

  def caveats
    <<~EOS
      The ArcadeDB root password was set to 'playwithdata'.
    EOS
  end

  #service do
  #  run libexec/"bin/server.sh"
  #  keep_alive true
  #  working_dir libexec
  #  log_path var/"log/arcadedb/arcadedb.log"
  #  error_log_path var/"log/arcadedb/arcadedb.err"
  #end

  test do
    system "false"
  end

end
