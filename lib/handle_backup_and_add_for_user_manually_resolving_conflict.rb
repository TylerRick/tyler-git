require 'colored'

# also handles checking for conflict markers
def handle_backup_and_add_for_user_manually_resolving_conflict(path, backup_path)
  begin
    path.cp backup_path

    yield

    add_file = true

    system "git-file-has-no-conflict-markers #{path}"
    if add_file && !$?.success?
      STDERR.puts "Warning: File still contains conflict markers (<<<<<<<, etc.). You will probably want to fix that before marking it as resolved.".red
      add_file = false
    end

    #`test #{path} -nt #{backup_path}`
    #newer = $?.success?
    newer = path.mtime > backup_path.mtime

    #system "git diff-index --exit-code --name-status HEAD -- #{path}"
    #changed = !$?.success?
    # Is the file still unmerged?
    system "git diff-index --exit-code --name-status --diff-filter=U HEAD -- #{path}"
    unmerged = $?.success?

    #if add_file && (!changed || !newer)
    if add_file && unmerged && !newer
      add_file = false
      puts "#{path} seems unchanged.".red
      print "Was the merge successful? y/[n] ".cyan
      response = STDIN.gets
      if response[0..0].downcase == 'y'
        add_file = true
      end
    end
    if add_file
      puts "Marking file as resolved: #{path}".green
      # does this handle if file *removed* also?
      system "git add -u #{path}"
    end

  ensure
    backup_path.unlink rescue nil #(puts "Warning: tried to remove #{backup_path} but could not (perhaps you already removed it?)")
  end
end
