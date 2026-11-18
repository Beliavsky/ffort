program keyword_oracle
implicit none
integer :: number
logical :: enabled
real(8) :: factor
number=4
enabled=.false.
factor=2.5d0
call transform(factor=factor,enabled=enabled,number=number)
print *,number,enabled,factor
contains
subroutine transform(number,enabled,factor)
integer,intent(inout) :: number
logical,intent(out) :: enabled
real(8),intent(inout) :: factor
number=number+2
enabled=.true.
factor=factor*2.0d0
end subroutine transform

end program
