program keyword_oracle
implicit none
integer :: aa(2,3)
aa=1
call transform(delta=4,values=aa(2:1:-1,3:1:-2))
print *,aa
contains
subroutine transform(values,delta)
integer,intent(inout) :: values(:,:)
integer,intent(in) :: delta
values=values+delta
end subroutine transform

end program
