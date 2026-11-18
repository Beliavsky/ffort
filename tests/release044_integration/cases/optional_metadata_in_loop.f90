program p
implicit none
character(24)::fmt
fmt='(*(i0,1x))'
call emit(fmt)
contains
subroutine emit(f,x)
character(*),intent(in)::f
character(*),optional,intent(in)::x
integer::i
write(*,fmt=f)(kind(x%len),i=1,3)
end subroutine
end program
