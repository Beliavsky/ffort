program keyword_oracle
implicit none
integer :: aa(2)
aa=3
print *,777
call transform(value=real(aa))
contains
subroutine transform(value)
real,intent(out) :: value(:)
value=3.0
end subroutine transform

end program
