module formats
implicit none
private
character(*),parameter,public::fmt='(a,i0)'
end module
program p
use formats,only:fmt
implicit none
print fmt,'m',2
end program
