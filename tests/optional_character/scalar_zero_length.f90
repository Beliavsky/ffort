program main
implicit none
character(0)::z
z=''
call check(z)
call check()
print *, 'PASS' 
contains
subroutine check(x)
character(*),optional,intent(in)::x
if(present(x)) then
if(len(x)/=0.or.x/='') error stop 1
end if
end subroutine
end program
