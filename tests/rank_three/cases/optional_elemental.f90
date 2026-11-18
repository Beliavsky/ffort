program rankthree
implicit none
integer :: aa(2,2,2)
aa=2
call maybe(aa)
call maybe()
aa=square(aa)
call bump(aa)
print *,aa
contains
subroutine maybe(xx)
integer,intent(inout),optional :: xx(:,:,:)
if (present(xx)) then
xx=xx+1
end if
end subroutine maybe
elemental integer function square(x) result(r)
integer,intent(in) :: x
r=x*x
end function square
elemental subroutine bump(x)
integer,intent(inout) :: x
x=x+1
end subroutine bump
end program rankthree
