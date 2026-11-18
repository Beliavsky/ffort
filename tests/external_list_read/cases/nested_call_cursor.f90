module m
implicit none
contains
subroutine read_one(u,a)
integer,intent(in)::u
integer,intent(out)::a
read(u,*)a
end subroutine
subroutine replay_one(u,a)
integer,intent(in)::u
integer,intent(out)::a
backspace(u)
call read_one(u,a)
end subroutine
end module
program p
use m
implicit none
integer::u,a,b,c
u=27
call read_one(u,a)
call read_one(u,b)
call replay_one(u,c)
print *,a,b,c
end program
