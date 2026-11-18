program p
implicit none
call f([integer(8)::],[real(8)::],[logical::])
print *, 'PASS'
contains
subroutine f(a,b,c)
integer(8),intent(in)::a(:)
real(8),intent(in)::b(:)
logical,intent(in)::c(:)
if(size(a)+size(b)+size(c)/=0) error stop 1
if(kind(a)/=8.or.kind(b)/=8) error stop 2
end subroutine
end program
