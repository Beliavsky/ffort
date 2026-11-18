program main
implicit none

call work()
contains
subroutine work(i)
integer,intent(in),optional::i
integer::a(3)
a=[(i,i=1,3)]
print *,a,present(i)
end subroutine
end program
