program keyword_oracle
implicit none
integer :: aa(3)
aa=9
call transform(right=aa(3:1),left=aa(2:1))
print *,aa
contains
subroutine transform(left,right)
integer,intent(out) :: left(:),right(:)
left=2
right=3
end subroutine transform

end program
