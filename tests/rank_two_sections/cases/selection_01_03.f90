program section_oracle
implicit none
integer :: aa(-2:3,4:8),bb(3,3),i,j
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
print *, aa(::2,8:4:-2)
print *,size(aa(::2,8:4:-2))
print *,size(aa(::2,8:4:-2),1)
print *,size(aa(::2,8:4:-2),2)
print *,lbound(aa(::2,8:4:-2),1),ubound(aa(::2,8:4:-2),1)
print *,lbound(aa(::2,8:4:-2),2),ubound(aa(::2,8:4:-2),2)
bb=aa(::2,8:4:-2)+2
print *,bb
aa(::2,8:4:-2)=aa(::2,8:4:-2)+1000
print *,aa
end program section_oracle
