program main
implicit none
integer::i
i=99
call emit([(i*i,i=1,4)])
print *,i
contains
subroutine emit(a)
integer,intent(in)::a(:)
print *,a
end subroutine
end program
