program rankthree
implicit none
integer :: aa(2,3,4),bb(4,3,2)
aa=1
bb=1
call copy(aa,bb)
contains
subroutine copy(x,y)
integer,intent(in) :: x(:,:,:)
integer,intent(out) :: y(:,:,:)
y=x
end subroutine copy
end program rankthree
