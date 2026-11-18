program main
implicit none
integer::n
n=4
call work(n)
contains
subroutine work(n)
integer,intent(in)::n
integer::i
write(*,*) (i*i,i=1,n)
print *,i
end subroutine
end program
