program keyword_oracle
implicit none
integer :: aa(4),ii
aa=0
ii=2
call transform(index_value=ii,value=aa(ii))
print *,aa,ii
contains
subroutine transform(value,index_value)
integer,intent(out) :: value,index_value
index_value=4
value=7
end subroutine transform

end program
