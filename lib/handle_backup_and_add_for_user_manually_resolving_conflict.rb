# also handles checking for conflict markers
def handle_backup_and_add_for_user_manually_resolving_conflict(path, backup_path)
  begin
    path.cp backup_path

    yield

    add_file = true

    system "git-file-has-conflict-markers #{path}"
    if add_file && $?.success?
      STDERR.puts "Warning: File still contains conflict markers (<<<<<<<, etc.). You will probably want to fix that before marking it as resolved."
      add_file = false
    end

    #`test #{path} -nt #{backup_path}`
    #newer = $?.success?
    #newer = path.mtime > backup_path.mtime
    system "git diff-index --exit-code --name-status HEAD -- #{path}"
    changed = !$?.success?

    if add_file && !changed
      add_file = false
      puts "#{path} seems unchanged.".red
      print "Was the merge successful? [y/n] ".cyan
      response = STDIN.gets
      if response[0..0].downcase == 'y'
        add_file = true
      end
    end
    if add_file
      puts "Marking file as resolved: #{path}"
      system "git add #{path}"
    end

  ensure
    backup_path.unlink rescue (puts "Warning: tried to remove #{backup_path} but could not (perhaps you already removed it?)")
  end
end
