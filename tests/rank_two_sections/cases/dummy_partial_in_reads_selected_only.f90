program section_oracle
implicit none
integer :: aa(3,3)
aa(3,3)=71
print *,first(aa(3:1:-1,3:1:-1))
contains
integer function first(xx) result(ans)
integer,intent(in)::xx(:,:)
ans=xx(1,1)
end function
end program section_oracle
