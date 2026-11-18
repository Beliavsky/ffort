program smoke
use fi_repl, only: run_repl
integer::status
call run_repl(status,show_prompt=.false.,show_banner=.false.)
if(status/=0) stop 1
end program
