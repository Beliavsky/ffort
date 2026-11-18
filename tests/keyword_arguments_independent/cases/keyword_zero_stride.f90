program keyword_oracle
implicit none
integer :: aa(2),ss
ss=0
call transform(value=aa(::ss))
contains
subroutine transform(value)
integer,intent(out) :: value(:)
value=2
end subroutine transform

end program
