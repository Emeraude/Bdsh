#/usr/bin/env ruby

`ls /bin /usr/bin`.split("\n").each do|cmd|
  if `echo #{cmd} | ./allowed_cmd`.split("\n")[0] != cmd
      puts cmd
  end
end
